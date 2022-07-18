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
#import "UIBarButtonItem+FLEX.h"
#import "FLEXManager+FWDebug.h"
#import "FLEXUtility.h"
#import "FLEXAlert.h"
#import "FLEXResources.h"
#import "FLEXMITMDataSource.h"
#import "FLEXNetworkTransaction.h"
#import "FLEXNetworkRecorder.h"
#import "FLEXNetworkCurlLogger.h"
#import "FLEXHTTPTransactionDetailController.h"
#import "FLEXWebViewController.h"
#import "FLEXImagePreviewViewController.h"
#import "GCDWebServerURLEncodedFormRequest.h"
#import "FLEXOSLogController.h"
#import "FLEXSystemLogCell.h"
#import <WebKit/WebKit.h>

@interface FLEXOSLogController ()

+ (FLEXOSLogController *)sharedLogController;

@end

@interface FLEXSystemLogCell ()

+ (NSString *)logTimeStringFromDate:(NSDate *)date;

@end

@interface FLEXNetworkRecorder ()

@property (nonatomic) dispatch_queue_t queue;

@end

@interface FLEXWebViewController ()

@property (nonatomic) NSString *originalText;

@end

typedef UIViewController *(^FLEXNetworkDetailRowSelectionFuture)(void);

@interface FLEXNetworkDetailRow : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detailText;
@property (nonatomic, copy) FLEXNetworkDetailRowSelectionFuture selectionFuture;

@end

@interface FLEXNetworkDetailSection : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<FLEXNetworkDetailRow *> *rows;

@end

@interface FLEXHTTPTransactionDetailController ()

@property (nonatomic, readonly) FLEXHTTPTransaction *transaction;
@property (nonatomic, copy) NSArray<FLEXNetworkDetailSection *> *sections;
+ (FLEXNetworkDetailSection *)generalSectionForTransaction:(FLEXHTTPTransaction *)transaction;
+ (FLEXNetworkDetailSection *)requestHeadersSectionForTransaction:(FLEXHTTPTransaction *)transaction;
+ (FLEXNetworkDetailSection *)postBodySectionForTransaction:(FLEXHTTPTransaction *)transaction;
+ (FLEXNetworkDetailSection *)queryParametersSectionForTransaction:(FLEXHTTPTransaction *)transaction;
+ (FLEXNetworkDetailSection *)responseHeadersSectionForTransaction:(FLEXHTTPTransaction *)transaction;
+ (NSData *)postBodyDataForTransaction:(FLEXHTTPTransaction *)transaction;

@end

#pragma mark - FWDebugWebServer

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
        
        [_webDebug startWithPort:[FWDebugWebServer debugServerPort] bonjourName:@""];
    });
}

+ (NSInteger)debugServerPort
{
    NSInteger port = [NSUserDefaults.standardUserDefaults integerForKey:@"FWDebugDebugServerPort"];
    if (port < 1) port = 8000;
    return port;
}

+ (NSInteger)webServerPort
{
    NSInteger port = [NSUserDefaults.standardUserDefaults integerForKey:@"FWDebugWebServerPort"];
    if (port < 1) port = 8001;
    return port;
}

+ (NSInteger)webDAVServerPort
{
    NSInteger port = [NSUserDefaults.standardUserDefaults integerForKey:@"FWDebugWebDAVServerPort"];
    if (port < 1) port = 8002;
    return port;
}

+ (NSInteger)webSiteServerPort
{
    NSInteger port = [NSUserDefaults.standardUserDefaults integerForKey:@"FWDebugWebSiteServerPort"];
    if (port < 1) port = 8003;
    return port;
}

+ (NSString *)debugServerPath
{
    NSString *path = [[[NSBundle bundleForClass:[FWDebugWebServer class]] resourcePath] stringByAppendingPathComponent:@"GCDWebUploader.bundle/Contents/Resources/"];
    return path;
}

+ (NSString *)webServerPath
{
    NSString *path = [NSUserDefaults.standardUserDefaults stringForKey:@"FWDebugWebServerPath"];
    if (!path) path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return path;
}

+ (NSString *)webDAVServerPath
{
    NSString *path = [NSUserDefaults.standardUserDefaults stringForKey:@"FWDebugWebDAVServerPath"];
    if (!path) path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return path;
}

+ (NSString *)webSiteServerPath
{
    NSString *path = [NSUserDefaults.standardUserDefaults stringForKey:@"FWDebugWebSiteServerPath"];
    if (!path) path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"website"];
    return path;
}

+ (void)setupServer
{
    //初始化WebDebug
    if (!_webDebug) {
        NSString *webPath = [FWDebugWebServer debugServerPath];
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
                    @"footer": [NSString stringWithFormat:@"%@ %@", title, version],
                }];
            } else {
                return [GCDWebServerErrorResponse responseWithClientError:kGCDWebServerHTTPStatusCode_NotFound message:@"\"%@\" does not exist", path];
            }
        }];
        
        [_webDebug addHandlerForMethod:@"POST"
                                  path:@"/settings"
                          requestClass:[GCDWebServerRequest class]
                     asyncProcessBlock:^(__kindof GCDWebServerRequest * request, GCDWebServerCompletionBlock completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [FLEXManager.sharedManager toggleExplorer];
                
                completionBlock([GCDWebServerDataResponse responseWithJSONObject:@{
                    @"debug": @([FLEXManager fwDebugVisible]),
                }]);
            });
        }];
        
        [_webDebug addHandlerForMethod:@"GET"
                                  path:@"/requests"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
            FLEXMITMDataSource<FLEXHTTPTransaction *> *dataSource = [FLEXMITMDataSource dataSourceWithProvider:^NSArray * {
                return FLEXNetworkRecorder.defaultRecorder.HTTPTransactions;
            }];
            NSString *keywords = request.query[@"keywords"] ?: @"";
            BOOL sort = [(request.query[@"sort"] ?: @"0") boolValue];
            NSInteger page = [(request.query[@"page"] ?: @"") integerValue];
            NSInteger perpage = [(request.query[@"perpage"] ?: @"") integerValue];
            if (page < 1) page = 1;
            if (perpage < 1) perpage = 10;
            
            NSMutableArray *array = [NSMutableArray array];
            __block NSInteger totalCount = 0;
            __block NSInteger bytesReceived = 0;
            [dataSource.transactions enumerateObjectsWithOptions:sort ? NSEnumerationReverse : 0 usingBlock:^(FLEXHTTPTransaction *transaction, NSUInteger idx, BOOL *stop) {
                if (keywords.length > 0) {
                    if (![transaction matchesQuery:keywords]) return;
                }
                
                totalCount += 1;
                bytesReceived += transaction.receivedDataLength;
                if (totalCount > perpage * (page - 1) && totalCount <= perpage * page) {
                    NSData *imageData = UIImagePNGRepresentation(transaction.thumbnail);
                    NSString *imageString = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
                    if (imageString) imageString = [@"data:image/png;base64," stringByAppendingString:imageString];
                    NSString *title = transaction.primaryDescription;
                    if ([title containsString:@"?"]) title = [title componentsSeparatedByString:@"?"].firstObject;
                    
                    [array addObject:@{
                        @"path": transaction.requestID,
                        @"image": imageString ?: @"",
                        @"title": title ?: @"",
                        @"name": transaction.request.URL.absoluteString ?: @"",
                        @"date": transaction.tertiaryDescription ?: @"",
                        @"error": transaction.displayAsError ? @YES : @NO,
                        @"action": @"detail",
                        @"copy": transaction.request.URL.absoluteString ?: @"",
                    }];
                }
            }];
            
            NSInteger totalPage = ((NSInteger)(totalCount / perpage)) + ((totalCount % perpage) > 0 ? 1 : 0);
            NSString *byteCountText = [NSByteCountFormatter stringFromByteCount:bytesReceived countStyle:NSByteCountFormatterCountStyleBinary];
            NSString *totalText = [NSString stringWithFormat:@"%@ %@, Page %@ of %@ (%@ received)", @(totalCount), totalCount < 2 ? @"Request" : @"Requests", @(totalPage > 0 ? page : 0), @(totalPage), byteCountText];
            return [GCDWebServerDataResponse responseWithJSONObject:@{
                @"total": totalText,
                @"pager": @YES,
                @"next": totalPage > page ? @YES : @NO,
                @"prev": page > 1 ? @YES : @NO,
                @"list": array,
                @"debug": @([FLEXManager fwDebugVisible]),
            }];
        }];
        
        [_webDebug addHandlerForMethod:@"GET"
                                  path:@"/request"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
            NSString *requestID = request.query[@"path"] ?: @"";
            __block FLEXHTTPTransaction *transaction = nil;
            [FLEXNetworkRecorder.defaultRecorder.HTTPTransactions enumerateObjectsUsingBlock:^(FLEXHTTPTransaction *obj, NSUInteger idx, BOOL *stop) {
                if ([obj.requestID isEqualToString:requestID]) {
                    transaction = obj;
                    *stop = YES;
                }
            }];
            if (!transaction) {
                return [GCDWebServerDataResponse responseWithJSONObject:@{
                    @"total": @"",
                    @"pager": @NO,
                    @"next": @NO,
                    @"prev": @NO,
                    @"list": @[],
                    @"debug": @([FLEXManager fwDebugVisible]),
                }];
            }
            
            NSArray *array = [self transactionSections:transaction];
            return [GCDWebServerDataResponse responseWithJSONObject:@{
                @"total": @"",
                @"pager": @NO,
                @"next": @NO,
                @"prev": @NO,
                @"list": array,
                @"debug": @([FLEXManager fwDebugVisible]),
            }];
        }];
        
        [_webDebug addHandlerForMethod:@"DELETE"
                                  path:@"/requests"
                          requestClass:[GCDWebServerRequest class]
                     asyncProcessBlock:^(__kindof GCDWebServerRequest * request, GCDWebServerCompletionBlock completionBlock) {
            [FLEXNetworkRecorder.defaultRecorder clearRecordedActivity];
            
            dispatch_async(FLEXNetworkRecorder.defaultRecorder.queue, ^{
                completionBlock([GCDWebServerDataResponse responseWithJSONObject:@{}]);
            });
        }];
        
        [_webDebug addHandlerForMethod:@"DELETE"
                                  path:@"/wkwebview"
                          requestClass:[GCDWebServerRequest class]
                     asyncProcessBlock:^(__kindof GCDWebServerRequest * request, GCDWebServerCompletionBlock completionBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSSet<NSString *> *dataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
                NSDate *sinceDate = [NSDate dateWithTimeIntervalSince1970:0];
                [WKWebsiteDataStore.defaultDataStore removeDataOfTypes:dataTypes modifiedSince:sinceDate completionHandler:^{
                    completionBlock([GCDWebServerDataResponse responseWithJSONObject:@{}]);
                }];
            });
        }];
        
        [_webDebug addHandlerForMethod:@"GET"
                                  path:@"/logs"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
            NSArray<FLEXSystemLogMessage *> *messages = [FLEXOSLogController sharedLogController].messages.copy;
            NSString *keywords = request.query[@"keywords"] ?: @"";
            BOOL sort = [(request.query[@"sort"] ?: @"0") boolValue];
            NSInteger page = [(request.query[@"page"] ?: @"") integerValue];
            NSInteger perpage = [(request.query[@"perpage"] ?: @"") integerValue];
            if (page < 1) page = 1;
            if (perpage < 1) perpage = 10;
            
            NSMutableArray *array = [NSMutableArray array];
            __block NSInteger totalCount = 0;
            [messages enumerateObjectsWithOptions:sort ? 0 : NSEnumerationReverse usingBlock:^(FLEXSystemLogMessage *message, NSUInteger idx, BOOL *stop) {
                if (keywords.length > 0) {
                    NSString *text = [FLEXSystemLogCell displayedTextForLogMessage:message];
                    if (![text localizedCaseInsensitiveContainsString:keywords]) return;
                }
                
                totalCount += 1;
                if (totalCount > perpage * (page - 1) && totalCount <= perpage * page) {
                    [array addObject:@{
                        @"name": message.messageText ?: @"",
                        @"path": message.messageText ?: @"",
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
                @"debug": @([FLEXManager fwDebugVisible]),
            }];
        }];
        
        [_webDebug addHandlerForMethod:@"DELETE"
                                  path:@"/logs"
                          requestClass:[GCDWebServerRequest class]
                     asyncProcessBlock:^(__kindof GCDWebServerRequest * request, GCDWebServerCompletionBlock completionBlock) {
            FLEXOSLogController.sharedLogController.persistent = NO;
            FLEXOSLogController.sharedLogController.persistent = YES;
            
            completionBlock([GCDWebServerDataResponse responseWithJSONObject:@{}]);
        }];
        
        [_webDebug addHandlerForMethod:@"GET"
                                  path:@"/urls"
                          requestClass:[GCDWebServerRequest class]
                          processBlock:^GCDWebServerResponse * _Nullable(__kindof GCDWebServerRequest * _Nonnull request) {
            NSArray *urls = [NSUserDefaults.standardUserDefaults objectForKey:@"FWDebugOpenUrls"];
            if (![urls isKindOfClass:[NSArray class]]) urls = @[];
            NSString *keywords = request.query[@"keywords"] ?: @"";
            BOOL sort = [(request.query[@"sort"] ?: @"0") boolValue];
            NSInteger page = [(request.query[@"page"] ?: @"") integerValue];
            NSInteger perpage = [(request.query[@"perpage"] ?: @"") integerValue];
            if (page < 1) page = 1;
            if (perpage < 1) perpage = 10;
            
            NSMutableArray *array = [NSMutableArray array];
            __block NSInteger totalCount = 0;
            [urls enumerateObjectsWithOptions:sort ? 0 : NSEnumerationReverse usingBlock:^(NSString *url, NSUInteger idx, BOOL *stop) {
                if (keywords.length > 0) {
                    if (![url localizedCaseInsensitiveContainsString:keywords]) return;
                }
                
                totalCount += 1;
                if (totalCount > perpage * (page - 1) && totalCount <= perpage * page) {
                    [array addObject:@{
                        @"name": url,
                        @"path": url,
                        @"date": @"",
                    }];
                }
            }];
            
            NSInteger totalPage = ((NSInteger)(totalCount / perpage)) + ((totalCount % perpage) > 0 ? 1 : 0);
            NSString *totalText = [NSString stringWithFormat:@"%@ %@, Page %@ of %@", @(totalCount), totalCount < 2 ? @"URL" : @"URLs", @(totalPage > 0 ? page : 0), @(totalPage)];
            NSString *url = [NSUserDefaults.standardUserDefaults stringForKey:@"FWDebugOpenUrl"] ?: @"";
            return [GCDWebServerDataResponse responseWithJSONObject:@{
                @"total": totalText,
                @"next": totalPage > page ? @YES : @NO,
                @"prev": page > 1 ? @YES : @NO,
                @"list": array,
                @"url": url,
                @"debug": @([FLEXManager fwDebugVisible]),
            }];
        }];
        
        [_webDebug addHandlerForMethod:@"GET"
                                  path:@"/url"
                          requestClass:[GCDWebServerRequest class]
                     asyncProcessBlock:^(__kindof GCDWebServerRequest *request, GCDWebServerCompletionBlock completionBlock) {
            NSString *url = request.query[@"url"] ?: @"";
            if (url.length > 0) {
                id current = [NSUserDefaults.standardUserDefaults objectForKey:@"FWDebugOpenUrls"];
                NSMutableArray *urls = [current isKindOfClass:[NSArray class]] ? [current mutableCopy] : [NSMutableArray array];
                [urls removeObject:url];
                [urls addObject:url];
                
                [NSUserDefaults.standardUserDefaults setObject:urls.copy forKey:@"FWDebugOpenUrls"];
                [NSUserDefaults.standardUserDefaults setObject:url forKey:@"FWDebugOpenUrl"];
                [NSUserDefaults.standardUserDefaults synchronize];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [FLEXManager fwDebugOpenUrl:url];
                
                completionBlock([GCDWebServerDataResponse responseWithJSONObject:@{}]);
            });
        }];
        
        [_webDebug addHandlerForMethod:@"DELETE"
                                  path:@"/urls"
                          requestClass:[GCDWebServerRequest class]
                     asyncProcessBlock:^(__kindof GCDWebServerRequest * request, GCDWebServerCompletionBlock completionBlock) {
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"FWDebugOpenUrls"];
            [NSUserDefaults.standardUserDefaults synchronize];
            
            completionBlock([GCDWebServerDataResponse responseWithJSONObject:@{}]);
        }];
    }
    
    //初始化WebServer
    if (!_webServer) {
        NSString *webPath = [FWDebugWebServer webServerPath];
        NSString *title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        _webServer = [[GCDWebUploader alloc] initWithUploadDirectory:webPath];
        _webServer.title = [title stringByAppendingString:@" - FWDebug"];
        _webServer.header = title;
        _webServer.prologue = @"<p>Drag &amp; drop files on this window or use the \"Upload Files&hellip;\" button to upload new files.</p>";
        _webServer.epilogue = @"";
        _webServer.footer = [NSString stringWithFormat:@"%@ %@", title, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    }
    
    //初始化WebDavServer
    if (!_webDavServer) {
        NSString *webDavPath = [FWDebugWebServer webDAVServerPath];
        _webDavServer = [[GCDWebDAVServer alloc] initWithUploadDirectory:webDavPath];
    }
    
    //初始化WebSite
    if (!_webSite) {
        NSString *webPath = [FWDebugWebServer webSiteServerPath];
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

+ (NSArray *)transactionSections:(FLEXHTTPTransaction *)transaction
{
    NSMutableArray *sections = [NSMutableArray array];
    
    FLEXNetworkDetailSection *generalSection = [FLEXHTTPTransactionDetailController generalSectionForTransaction:transaction];
    if (generalSection.rows.count > 0) {
        [sections addObject:@{
            @"name": generalSection.title ?: @"",
            @"date": @"CURL",
            @"action": @"curl",
            @"title": @"Curl Command",
            @"copy": [FLEXNetworkCurlLogger curlCommandString:transaction.request],
        }];
        for (FLEXNetworkDetailRow *row in generalSection.rows) {
            if ([row.title isEqualToString:@"Request URL"]) {
                [sections addObject:@{
                    @"name": [NSString stringWithFormat:@"%@: %@", row.title, row.detailText],
                    @"action": @"view",
                    @"type": @"link",
                    @"path": row.detailText ?: @"",
                    @"copy": row.detailText ?: @"",
                }];
            } else if ([row.title isEqualToString:@"Request Body"]) {
                NSString *mimeType = [transaction.request valueForHTTPHeaderField:@"Content-Type"];
                if ([mimeType containsString:@";"]) mimeType = [mimeType componentsSeparatedByString:@";"].firstObject;
                NSData *requestData = [FLEXHTTPTransactionDetailController postBodyDataForTransaction:transaction];
                NSDictionary *detailSection = [self detailSection:row mimeType:mimeType data:requestData transaction:transaction];
                if (detailSection) {
                    [sections addObject:detailSection];
                } else {
                    [sections addObject:@{
                        @"name": [NSString stringWithFormat:@"%@: %@", row.title, mimeType ?: row.detailText],
                        @"action": @"view",
                        @"type": @"copy",
                        @"title": row.title ?: @"",
                        @"copy": @"Can't View HTTP Body Data",
                    }];
                }
            } else if ([row.title isEqualToString:@"Response Body"]) {
                NSString *mimeType = transaction.response.MIMEType;
                NSData *responseData = [FLEXNetworkRecorder.defaultRecorder cachedResponseBodyForTransaction:transaction];
                NSDictionary *detailSection = [self detailSection:row mimeType:mimeType data:responseData transaction:transaction];
                if (detailSection) {
                    [sections addObject:detailSection];
                } else {
                    [sections addObject:@{
                        @"name": [NSString stringWithFormat:@"%@: %@", row.title, mimeType ?: row.detailText],
                        @"action": @"view",
                        @"type": @"copy",
                        @"title": row.title ?: @"",
                        @"copy": @"Unable to View Response",
                    }];
                }
            } else {
                [sections addObject:[self detailSection:row]];
            }
        }
    }
    
    FLEXNetworkDetailSection *requestHeadersSection = [FLEXHTTPTransactionDetailController requestHeadersSectionForTransaction:transaction];
    if (requestHeadersSection.rows.count > 0) {
        [sections addObject:@{
            @"name": requestHeadersSection.title ?: @"",
            @"action": @"section",
            @"title": @"",
            @"copy": requestHeadersSection.title ?: @"",
        }];
        for (FLEXNetworkDetailRow *row in requestHeadersSection.rows) {
            [sections addObject:[self detailSection:row]];
        }
    }
    
    FLEXNetworkDetailSection *queryParametersSection = [FLEXHTTPTransactionDetailController queryParametersSectionForTransaction:transaction];
    if (queryParametersSection.rows.count > 0) {
        [sections addObject:@{
            @"name": queryParametersSection.title ?: @"",
            @"action": @"section",
            @"title": @"",
            @"copy": queryParametersSection.title ?: @"",
        }];
        for (FLEXNetworkDetailRow *row in queryParametersSection.rows) {
            [sections addObject:[self detailSection:row]];
        }
    }
    
    FLEXNetworkDetailSection *postBodySection = [FLEXHTTPTransactionDetailController postBodySectionForTransaction:transaction];
    if (postBodySection.rows.count > 0) {
        [sections addObject:@{
            @"name": postBodySection.title ?: @"",
            @"action": @"section",
            @"title": @"",
            @"copy": postBodySection.title ?: @"",
        }];
        for (FLEXNetworkDetailRow *row in postBodySection.rows) {
            [sections addObject:[self detailSection:row]];
        }
    }
    
    FLEXNetworkDetailSection *responseHeadersSection = [FLEXHTTPTransactionDetailController responseHeadersSectionForTransaction:transaction];
    if (responseHeadersSection.rows.count > 0) {
        [sections addObject:@{
            @"name": responseHeadersSection.title ?: @"",
            @"action": @"section",
            @"title": @"",
            @"copy": responseHeadersSection.title ?: @"",
        }];
        for (FLEXNetworkDetailRow *row in responseHeadersSection.rows) {
            [sections addObject:[self detailSection:row]];
        }
    }
    
    return sections;
}

+ (NSDictionary *)detailSection:(FLEXNetworkDetailRow *)row mimeType:(NSString *)mimeType data:(NSData *)data transaction:(FLEXHTTPTransaction *)transaction
{
    if (!data) return nil;
    
    if ([FLEXUtility isValidJSONData:data]) {
        NSString *prettyJSON = [FLEXUtility prettyJSONStringFromData:data];
        if (prettyJSON.length > 0) {
            return @{
                @"name": [NSString stringWithFormat:@"%@: %@", row.title, mimeType ?: row.detailText],
                @"action": @"view",
                @"type": @"json",
                @"title": row.title ?: @"",
                @"copy": prettyJSON,
            };
        }
    } else if ([mimeType hasPrefix:@"image/"]) {
        NSString *imageString = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        if (imageString) imageString = [NSString stringWithFormat:@"data:%@;base64,%@", mimeType, imageString];
        return @{
            @"name": [NSString stringWithFormat:@"%@: %@", row.title, mimeType ?: row.detailText],
            @"action": @"view",
            @"type": @"image",
            @"path": imageString ?: @"",
            @"title": row.title ?: @"",
            @"copy": transaction.request.URL.absoluteString ?: @"",
        };
    } else if ([mimeType isEqual:@"application/x-plist"]) {
        id propertyList = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:NULL];
        return @{
            @"name": [NSString stringWithFormat:@"%@: %@", row.title, mimeType ?: row.detailText],
            @"action": @"view",
            @"type": @"copy",
            @"title": row.title ?: @"",
            @"copy": [propertyList description] ?: @"",
        };
    }
    
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (text.length > 0) {
        return @{
            @"name": [NSString stringWithFormat:@"%@: %@", row.title, mimeType ?: row.detailText],
            @"action": @"view",
            @"type": @"copy",
            @"title": row.title ?: @"",
            @"copy": text,
        };
    }
    
    return nil;
}

+ (NSDictionary *)detailSection:(FLEXNetworkDetailRow *)row
{
    NSData *data = row.detailText ? [row.detailText dataUsingEncoding:NSUTF8StringEncoding] : nil;
    if (data && [FLEXUtility isValidJSONData:data]) {
        NSString *prettyJSON = [FLEXUtility prettyJSONStringFromData:data];
        if (prettyJSON.length > 0) {
            return @{
                @"name": [NSString stringWithFormat:@"%@: %@", row.title, row.detailText],
                @"action": @"copy",
                @"type": @"json",
                @"title": row.title ?: @"",
                @"copy": prettyJSON,
            };
        }
    }
    
    return @{
        @"name": [NSString stringWithFormat:@"%@: %@", row.title, row.detailText],
        @"action": @"copy",
        @"title": row.title ?: @"",
        @"copy": row.detailText ?: @"",
    };
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
    
    [self addToolbarItems:@[
        [UIBarButtonItem
            flex_itemWithImage:FLEXResources.gearIcon
            target:self
            action:@selector(actionSettings:)
        ],
    ]];
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
            port = [FWDebugWebServer webServerPort];
            break;
        }
        case 2: {
            server = _webDavServer;
            port = [FWDebugWebServer webDAVServerPort];
            break;
        }
        case 3: {
            server = _webSite;
            port = [FWDebugWebServer webSiteServerPort];
            break;
        }
        default: {
            server = _webDebug;
            port = [FWDebugWebServer debugServerPort];
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

- (void)actionSettings:(UIBarButtonItem *)sender {
    [FLEXAlert makeSheet:^(FLEXAlert *make) {
        make.title(@"Web Server Settings");
        
        make.button(@"Cancel").cancelStyle();
        make.button(@"Debug Server Port")
            .handler(^(NSArray<NSString *> *strings) {
                [FWDebugManager showPrompt:self security:NO title:@"Input Value" message:nil text:[NSString stringWithFormat:@"%@", @([FWDebugWebServer debugServerPort])] block:^(BOOL confirm, NSString *text) {
                    if (!confirm) return;
                    
                    if (text.length < 1) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"FWDebugDebugServerPort"];
                        [NSUserDefaults.standardUserDefaults synchronize];
                        return;
                    }
                    
                    [NSUserDefaults.standardUserDefaults setInteger:text.integerValue forKey:@"FWDebugDebugServerPort"];
                    [NSUserDefaults.standardUserDefaults synchronize];
                }];
        });
        make.button(@"Web Server Port")
            .handler(^(NSArray<NSString *> * _Nonnull strings) {
                [FWDebugManager showPrompt:self security:NO title:@"Input Value" message:nil text:[NSString stringWithFormat:@"%@", @([FWDebugWebServer webServerPort])] block:^(BOOL confirm, NSString *text) {
                    if (!confirm) return;
                    
                    if (text.length < 1) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"FWDebugWebServerPort"];
                        [NSUserDefaults.standardUserDefaults synchronize];
                        return;
                    }
                    
                    [NSUserDefaults.standardUserDefaults setInteger:text.integerValue forKey:@"FWDebugWebServerPort"];
                    [NSUserDefaults.standardUserDefaults synchronize];
                }];
        });
        make.button(@"Web Server Path")
            .handler(^(NSArray<NSString *> * _Nonnull strings) {
                [FWDebugManager showPrompt:self security:NO title:@"Input Value" message:nil text:[FWDebugWebServer webServerPath] block:^(BOOL confirm, NSString *text) {
                    if (!confirm) return;
                    
                    if (text.length < 1) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"FWDebugWebServerPath"];
                        [NSUserDefaults.standardUserDefaults synchronize];
                        return;
                    }
                    
                    [NSUserDefaults.standardUserDefaults setObject:text forKey:@"FWDebugWebServerPath"];
                    [NSUserDefaults.standardUserDefaults synchronize];
                }];
        });
        make.button(@"WebDAV Server Port")
            .handler(^(NSArray<NSString *> * _Nonnull strings) {
                [FWDebugManager showPrompt:self security:NO title:@"Input Value" message:nil text:[NSString stringWithFormat:@"%@", @([FWDebugWebServer webDAVServerPort])] block:^(BOOL confirm, NSString *text) {
                    if (!confirm) return;
                    
                    if (text.length < 1) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"FWDebugWebDAVServerPort"];
                        [NSUserDefaults.standardUserDefaults synchronize];
                        return;
                    }
                    
                    [NSUserDefaults.standardUserDefaults setInteger:text.integerValue forKey:@"FWDebugWebDAVServerPort"];
                    [NSUserDefaults.standardUserDefaults synchronize];
                }];
        });
        make.button(@"WebDAV Server Path")
            .handler(^(NSArray<NSString *> * _Nonnull strings) {
                [FWDebugManager showPrompt:self security:NO title:@"Input Value" message:nil text:[FWDebugWebServer webDAVServerPath] block:^(BOOL confirm, NSString *text) {
                    if (!confirm) return;
                    
                    if (text.length < 1) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"FWDebugWebDAVServerPath"];
                        [NSUserDefaults.standardUserDefaults synchronize];
                        return;
                    }
                    
                    [NSUserDefaults.standardUserDefaults setObject:text forKey:@"FWDebugWebDAVServerPath"];
                    [NSUserDefaults.standardUserDefaults synchronize];
                }];
        });
        make.button(@"WebSite Server Port")
            .handler(^(NSArray<NSString *> * _Nonnull strings) {
                [FWDebugManager showPrompt:self security:NO title:@"Input Value" message:nil text:[NSString stringWithFormat:@"%@", @([FWDebugWebServer webSiteServerPort])] block:^(BOOL confirm, NSString *text) {
                    if (!confirm) return;
                    
                    if (text.length < 1) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"FWDebugWebSiteServerPort"];
                        [NSUserDefaults.standardUserDefaults synchronize];
                        return;
                    }
                    
                    [NSUserDefaults.standardUserDefaults setInteger:text.integerValue forKey:@"FWDebugWebSiteServerPort"];
                    [NSUserDefaults.standardUserDefaults synchronize];
                }];
        });
        make.button(@"WebSite Server Path")
            .handler(^(NSArray<NSString *> * _Nonnull strings) {
                [FWDebugManager showPrompt:self security:NO title:@"Input Value" message:nil text:[FWDebugWebServer webSiteServerPath] block:^(BOOL confirm, NSString *text) {
                    if (!confirm) return;
                    
                    if (text.length < 1) {
                        [NSUserDefaults.standardUserDefaults removeObjectForKey:@"FWDebugWebSiteServerPath"];
                        [NSUserDefaults.standardUserDefaults synchronize];
                        return;
                    }
                    
                    [NSUserDefaults.standardUserDefaults setObject:text forKey:@"FWDebugWebSiteServerPath"];
                    [NSUserDefaults.standardUserDefaults synchronize];
                }];
        });
    } showFrom:self source:sender];
}

@end
