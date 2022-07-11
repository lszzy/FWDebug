//
//  FWDebugGCDWebServer.m
//  FWDebug
//
//  Created by wuyong on 17/2/22.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugWebServer.h"
#import "GCDWebDAVServer.h"
#import "GCDWebUploader.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerErrorResponse.h"
#import "FWDebugManager+FWDebug.h"
#import "NSUserDefaults+FLEX.h"
#import "FLEXMITMDataSource.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXOSLogController.h"
#import "FLEXSystemLogCell.h"

@interface FLEXOSLogController ()

+ (FLEXOSLogController *)sharedLogController;

@end

@interface FLEXSystemLogCell ()

+ (NSString *)logTimeStringFromDate:(NSDate *)date;

@end

#pragma mark - FWDebugWebServer

#define FWDebugWebDebugPort 8000
#define FWDebugWebServerPort 8001
#define FWDebugWebDavServerPort 8002
#define FWDebugWebSitePort 8003

// 静态服务器变量
static GCDWebServer *_webDebug = nil;
static GCDWebUploader *_webServer = nil;
static GCDWebDAVServer *_webDavServer = nil;
static GCDWebServer *_webSite = nil;

@interface FWDebugWebServer ()

@end

@implementation FWDebugWebServer

+ (void)fwDebugLaunch
{
    BOOL webDebugEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"FWDebugWebDebugEnabled"];
    if (!webDebugEnabled) return;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupServer];
        
        [_webDebug startWithPort:FWDebugWebDebugPort bonjourName:@""];
    });
}

+ (void)setupServer
{
    //初始化WebDebug
    if (!_webDebug) {
        NSString *webPath = [[[NSBundle bundleForClass:[FWDebugWebServer class]] resourcePath] stringByAppendingPathComponent:@"GCDWebUploader.bundle/Contents/Resources/"];
        _webDebug = [[GCDWebServer alloc] init];
        [_webDebug addGETHandlerForBasePath:@"/" directoryPath:webPath indexFilename:nil cacheAge:3600 allowRangeRequests:YES];
        [_webDebug addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
            return [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:@"index.html" relativeToURL:request.URL] permanent:NO];
        }];
        [_webDebug addHandlerForMethod:@"GET" pathRegex:@"/.*\\.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
            NSString *path = request.path;
            if ([path isEqualToString:@"/index.html"]) path = @"/debug.html";
            NSString *file = [webPath stringByAppendingPathComponent:path];
            if ([NSFileManager.defaultManager fileExistsAtPath:file]) {
                NSString *title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
                if (!title) title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
                NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                
                return [GCDWebServerDataResponse responseWithHTMLTemplate:file variables:@{
                    @"title": [title stringByAppendingString:@" - FWDebug"],
                    @"header": title,
                    @"keywords": request.query[@"keywords"] ?: @"",
                    @"footer": [NSString stringWithFormat:@"%@ %@ - FWDebug", title, version],
                }];
            } else {
                return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", path];
            }
        }];
        
        [_webDebug addHandlerForMethod:@"GET"
                                  path:@"/list"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
            FLEXMITMDataSource<FLEXHTTPTransaction *> *dataSource = [FLEXMITMDataSource dataSourceWithProvider:^NSArray * {
                return FLEXNetworkRecorder.defaultRecorder.HTTPTransactions;
            }];
            
            NSMutableArray *array = [NSMutableArray array];
            NSInteger bytesReceived = 0;
            for (FLEXHTTPTransaction *transaction in dataSource.transactions) {
                bytesReceived += transaction.receivedDataLength;
                [array addObject:@{
                    @"identifier": transaction.requestID,
                    @"thumbnail": @"",
                    @"name": transaction.primaryDescription,
                    @"path": transaction.secondaryDescription,
                    @"details": transaction.tertiaryDescription,
                    @"size": @(transaction.receivedDataLength),
                    @"error": transaction.displayAsError ? @YES : @NO,
                }];
            }
            
            NSString *byteCountText = [NSByteCountFormatter stringFromByteCount:bytesReceived countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *totalText = [NSString stringWithFormat:@"%@ %@ (%@ received)", @(array.count), array.count < 2 ? @"Request" : @"Requests", byteCountText];
            return [GCDWebServerDataResponse responseWithJSONObject:@{
                @"total": totalText,
                @"list": array,
            }];
        }];
        
        [_webDebug addHandlerForMethod:@"GET"
                                  path:@"/logs"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
            NSArray<FLEXSystemLogMessage *> *messages = [FLEXOSLogController sharedLogController].messages.copy;
            NSString *keywords = request.query[@"keywords"] ?: @"";
            NSInteger page = [(request.query[@"page"] ?: @"") integerValue];
            NSInteger perpage = [(request.query[@"perpage"] ?: @"") integerValue];
            if (page < 1) page = 1;
            if (perpage < 1) perpage = 10;
            
            NSMutableArray *array = [NSMutableArray array];
            __block NSInteger totalCount = 0;
            [messages enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(FLEXSystemLogMessage *message, NSUInteger idx, BOOL *stop) {
                if (keywords.length > 0) {
                    NSString *text = [FLEXSystemLogCell displayedTextForLogMessage:message];
                    if (![text localizedCaseInsensitiveContainsString:keywords]) return;
                }
                
                totalCount += 1;
                if (totalCount > perpage * (page - 1) && totalCount <= perpage * page) {
                    [array addObject:@{
                        @"name": message.messageText,
                        @"path": message.messageText,
                        @"date": [FLEXSystemLogCell logTimeStringFromDate:message.date],
                    }];
                }
            }];
            
            NSInteger totalPage = ((NSInteger)(totalCount / perpage)) + ((totalCount % perpage) > 0 ? 1 : 0);
            NSString *totalText = [NSString stringWithFormat:@"%@ %@, Page %@ of %@", @(totalCount), totalCount < 2 ? @"Log" : @"Logs", @(totalPage > 0 ? page : 0), @(totalPage)];
            return [GCDWebServerDataResponse responseWithJSONObject:@{
                @"total": totalText,
                @"next": totalPage > page ? @YES : @NO,
                @"prev": page > 1 ? @YES : @NO,
                @"list": array,
            }];
        }];
    }
    
    //初始化WebServer
    if (!_webServer) {
        NSString *webPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        _webServer = [[GCDWebUploader alloc] initWithUploadDirectory:webPath];
        _webServer.title = [title stringByAppendingString:@" - FWDebug"];
        _webServer.header = title;
        _webServer.prologue = @"<p>Drag &amp; drop files on this window or use the \"Upload Files&hellip;\" button to upload new files.</p>";
        _webServer.epilogue = @"";
        _webServer.footer = [NSString stringWithFormat:@"%@ %@ - FWDebug", title, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    }
    
    //初始化WebDavServer
    if (!_webDavServer) {
        NSString *webDavPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _webDavServer = [[GCDWebDAVServer alloc] initWithUploadDirectory:webDavPath];
    }
    
    //初始化WebSite
    if (!_webSite) {
        NSString *webPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"website"];
        _webSite = [[GCDWebServer alloc] init];
        [_webSite addGETHandlerForBasePath:@"/" directoryPath:webPath indexFilename:nil cacheAge:3600 allowRangeRequests:YES];
        [_webSite addHandlerForMethod:@"GET" pathRegex:@"/.*\\.html" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
            NSString *html = [[NSString alloc] initWithContentsOfFile:[webPath stringByAppendingPathComponent:request.path] encoding:NSUTF8StringEncoding error:NULL];
            if (html != nil) {
                return [GCDWebServerDataResponse responseWithHTML:html];
            } else {
                return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", request.path];
            }
        }];
        [_webSite addHandlerForMethod:@"GET" path:@"/" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
            return [GCDWebServerResponse responseWithRedirect:[NSURL URLWithString:@"index.html" relativeToURL:request.URL] permanent:NO];
        }];
    }
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        [FWDebugWebServer setupServer];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Web Server";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 1:
            return @"Web Server";
        case 2:
            return @"WebDav Server";
        case 3:
            return @"WebSite Server";
        default:
            return @"Debug Server";
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"WebServerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        
        UISwitch *accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
        [accessoryView addTarget:self action:@selector(actionSwitch:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = accessoryView;
    }
    
    [self configCell:cell indexPath:indexPath];
    
    return cell;
}

- (void)configCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    cellSwitch.tag = indexPath.section;
    
    GCDWebServer *server;
    BOOL autoStart = NO;
    switch (indexPath.section) {
        case 1: {
            server = _webServer;
            break;
        }
        case 2: {
            server = _webDavServer;
            break;
        }
        case 3: {
            server = _webSite;
            break;
        }
        default: {
            server = _webDebug;
            autoStart = YES;
            break;
        }
    }
    
    if (server.isRunning) {
        cell.textLabel.text = @"Server Started";
        cell.detailTextLabel.text = [server.serverURL absoluteString];
        cellSwitch.on = YES;
    } else {
        cell.textLabel.text = @"Server Stopped";
        cell.detailTextLabel.text = autoStart ? @"auto start when app launch" : nil;
        cellSwitch.on = NO;
    }
}

#pragma mark - Action
- (void)actionSwitch:(UISwitch *)sender {
    GCDWebServer *server;
    NSUInteger port;
    NSString *key;
    switch (sender.tag) {
        case 1: {
            server = _webServer;
            port = FWDebugWebServerPort;
            break;
        }
        case 2: {
            server = _webDavServer;
            port = FWDebugWebDavServerPort;
            break;
        }
        case 3: {
            server = _webSite;
            port = FWDebugWebSitePort;
            break;
        }
        default: {
            server = _webDebug;
            port = FWDebugWebDebugPort;
            key = @"FWDebugWebDebugEnabled";
            break;
        }
    }
    
    if (sender.on) {
        [server startWithPort:port bonjourName:@""];
        if (key.length > 0) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if (!FLEXOSLogController.sharedLogController.persistent) {
                NSUserDefaults.standardUserDefaults.flex_cacheOSLogMessages = YES;
                FLEXOSLogController.sharedLogController.persistent = YES;
                [FLEXOSLogController.sharedLogController startMonitoring];
            }
        }
    } else {
        [server stop];
        if (key.length > 0) {
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:sender.tag];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self configCell:cell indexPath:indexPath];
}

@end
