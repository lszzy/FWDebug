//
//  FLEXManager+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/28.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FLEXManager+FWDebug.h"
#import "FWDebugManager+FWDebug.h"
#import "FLEXExplorerViewController.h"
#import "FLEXFileBrowserTableViewController.h"
#import "FLEXObjectExplorerViewController+FWDebug.h"
#import "FLEXClassExplorerViewController+FWDebug.h"
#import "FLEXFileBrowserTableViewController+FWDebug.h"
#import "FLEXExplorerToolbar+FWDebug.h"
#import "FLEXSystemLogTableViewController+FWDebug.h"
#import "FLEXInstancesTableViewController+FWDebug.h"
#import "FLEXObjectExplorerFactory.h"
#import "FWDebugSystemInfo.h"
#import "FWDebugWebServer.h"
#import "FWDebugAppSecret.h"
#import <objc/runtime.h>

@interface FLEXManager ()

@property (nonatomic, strong) FLEXExplorerViewController *explorerViewController;

@end

@interface FLEXExplorerViewController ()

@property (nonatomic, strong) FLEXExplorerToolbar *explorerToolbar;

- (void)makeKeyAndPresentViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(void (^)(void))completion;

- (void)selectedViewExplorerFinished:(id)sender;

@end

@implementation FLEXManager (FWDebug)

+ (void)load
{
    [FWDebugManager fwDebugSwizzleInstance:self method:@selector(showExplorer) with:@selector(fwDebugShowExplorer)];
    [FWDebugManager fwDebugSwizzleInstance:self method:@selector(hideExplorer) with:@selector(fwDebugHideExplorer)];
}

+ (void)fwDebugLoad
{
    [FLEXManager sharedManager].networkDebuggingEnabled = YES;
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"📳  Device Info" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugSystemInfo alloc] init];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"📶  Web Server" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugWebServer alloc] init];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"💟  App Secret" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugAppSecret alloc] init];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"📘  App Browser" viewControllerFutureBlock:^UIViewController *{
        return [[FLEXFileBrowserTableViewController alloc] initWithPath:[NSBundle mainBundle].bundlePath];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"📝  Log Browser" viewControllerFutureBlock:^UIViewController *{
        NSString *fileLogPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        fileLogPath = [[fileLogPath stringByAppendingPathComponent:@"FWDebug"] stringByAppendingPathComponent:@"NSLog"];
        return [[FLEXFileBrowserTableViewController alloc] initWithPath:fileLogPath];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"🍀  Crash Log" viewControllerFutureBlock:^UIViewController *{
        NSString *crashLogPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        crashLogPath = [[crashLogPath stringByAppendingPathComponent:@"FWDebug"] stringByAppendingPathComponent:@"CrashLog"];
        return [[FLEXFileBrowserTableViewController alloc] initWithPath:crashLogPath];
    }];
}

- (FWDebugFpsInfo *)fwDebugFpsInfo
{
    FWDebugFpsInfo *fpsInfo = objc_getAssociatedObject(self, _cmd);
    if (!fpsInfo) {
        fpsInfo = [[FWDebugFpsInfo alloc] init];
        fpsInfo.delegate = self;
        objc_setAssociatedObject(self, _cmd, fpsInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [self.explorerViewController.explorerToolbar.fwDebugFpsItem addTarget:self action:@selector(fwDebugFpsItemClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.explorerViewController.explorerToolbar.fwDebugFpsItem setFpsData:fpsInfo.fpsData];
    }
    return fpsInfo;
}

- (void)fwDebugShowExplorer
{
    if ([FWDebugAppSecret isAppLocked]) {
        return;
    }
    
    [self fwDebugShowExplorer];
    
    [self.fwDebugFpsInfo start];
}

- (void)fwDebugHideExplorer
{
    if ([FWDebugAppSecret isAppLocked]) {
        return;
    }
    
    [self fwDebugHideExplorer];
    
    [self.fwDebugFpsInfo stop];
}

- (void)fwDebugFpsInfoChanged:(FWDebugFpsData *)fpsData
{
    [self.explorerViewController.explorerToolbar.fwDebugFpsItem setFpsData:fpsData];
}

- (void)fwDebugFpsItemClicked:(FLEXToolbarItem *)sender
{
    FLEXObjectExplorerViewController *viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:self.fwDebugFpsInfo.fpsData.currentController];
    viewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self.explorerViewController action:@selector(selectedViewExplorerFinished:)];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self.explorerViewController makeKeyAndPresentViewController:navigationController animated:YES completion:nil];
}

@end
