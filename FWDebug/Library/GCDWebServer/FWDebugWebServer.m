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
#import "FWDebugWebBundle.h"
#import "FWDebugManager+FWDebug.h"

#pragma mark - FWDebugWebServer

#define FWDebugWebServerPort 8001
#define FWDebugWebDavServerPort 8002

// 静态服务器变量
static GCDWebUploader *_webServer = nil;
static GCDWebDAVServer *_webDavServer = nil;

@interface FWDebugWebServer ()

@end

@implementation FWDebugWebServer

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        //初始化WebServer
        if (!_webServer) {
            NSString *webPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            _webServer = [[GCDWebUploader alloc] initWithUploadDirectory:webPath];
            _webServer.title = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
            _webServer.header = _webServer.title;
            _webServer.prologue = @"<p>Drag &amp; drop files on this window or use the \"Upload Files&hellip;\" button to upload new files.</p>";
            _webServer.epilogue = @"";
            _webServer.footer = [NSString stringWithFormat:@"%@ %@", _webServer.title, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
        }
        
        //初始化WebDavServer
        if (!_webDavServer) {
            NSString *webDavPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            _webDavServer = [[GCDWebDAVServer alloc] initWithUploadDirectory:webDavPath];
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Web Server";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Web Server" : @"WebDav Server";
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
    GCDWebServer *server = indexPath.section == 0 ? _webServer : _webDavServer;
    
    if (server.isRunning) {
        cell.textLabel.text = @"Server Started";
        cell.detailTextLabel.text = [server.serverURL absoluteString];
        cellSwitch.on = YES;
    } else {
        cell.textLabel.text = @"Server Stopped";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = NO;
    }
}

#pragma mark - Action
- (void)actionSwitch:(UISwitch *)sender {
    GCDWebServer *server = sender.tag == 0 ? _webServer : _webDavServer;
    NSUInteger port = sender.tag == 0 ? FWDebugWebServerPort : FWDebugWebDavServerPort;
    
    if (sender.on) {
        [server startWithPort:port bonjourName:@""];
    } else {
        [server stop];
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:sender.tag];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self configCell:cell indexPath:indexPath];
}

@end
