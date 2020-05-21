//
//  FLEXManager+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/28.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXManager+FWDebug.h"
#import "FLEXManager+Extensibility.h"
#import "FLEXManager+Networking.h"
#import "FLEXManager+Private.h"
#import "FWDebugManager+FWDebug.h"
#import "FLEXExplorerViewController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXNavigationController.h"
#import "FLEXObjectExplorerViewController+FWDebug.h"
#import "FLEXFileBrowserController+FWDebug.h"
#import "FLEXExplorerToolbar+FWDebug.h"
#import "FLEXObjectListViewController+FWDebug.h"
#import "FWDebugSystemInfo.h"
#import "FWDebugWebServer.h"
#import "FWDebugAppConfig.h"
#import "FWDebugFakeLocation.h"
#import "FWDebugFakeNotification.h"
#import <objc/runtime.h>

@implementation FLEXManager (FWDebug)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager fwDebugSwizzleMethod:@selector(showExplorer) in:self with:@selector(fwDebugShowExplorer) in:self];
        [FWDebugManager fwDebugSwizzleMethod:@selector(hideExplorer) in:self with:@selector(fwDebugHideExplorer) in:self];
    });
}

+ (void)fwDebugLoad
{
    [FLEXManager sharedManager].networkDebuggingEnabled = YES;
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"💟  Device Info" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugSystemInfo alloc] init];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"📳  Web Server" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugWebServer alloc] init];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"📍  Fake Location" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugFakeLocation alloc] init];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"🔴  Fake Notification" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugFakeNotification alloc] init];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"📝  Crash Log" viewControllerFutureBlock:^UIViewController *{
        NSString *crashLogPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        crashLogPath = [[crashLogPath stringByAppendingPathComponent:@"FWDebug"] stringByAppendingPathComponent:@"CrashLog"];
        return [[FLEXFileBrowserController alloc] initWithPath:crashLogPath];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"🍀  App Config" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugAppConfig alloc] init];
    }];
}

+ (void)fwDebugLaunch
{
    [FWDebugAppConfig fwDebugLaunch];
    [FWDebugFakeNotification fwDebugLaunch];
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
        
        UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(fwDebugFpsItemLongPressed:)];
        [self.explorerViewController.explorerToolbar.fwDebugFpsItem addGestureRecognizer:gestureRecognizer];
    }
    return fpsInfo;
}

- (void)fwDebugShowExplorer
{
    if ([FWDebugAppConfig isAppLocked]) {
        return;
    }
    
    [self fwDebugShowExplorer];
    
    [self.fwDebugFpsInfo start];
}

- (void)fwDebugHideExplorer
{
    if ([FWDebugAppConfig isAppLocked]) {
        return;
    }
    
    [self fwDebugHideExplorer];
    
    [self.fwDebugFpsInfo stop];
}

- (void)fwDebugFpsInfoChanged:(FWDebugFpsData *)fpsData
{
    [self.explorerViewController.explorerToolbar.fwDebugFpsItem setFpsData:fpsData];
}

- (void)fwDebugFpsItemClicked:(FLEXExplorerToolbarItem *)sender
{
    FLEXObjectExplorerViewController *viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:[self fwDebugViewController]];
    [self.explorerViewController presentViewController:[FLEXNavigationController withRootViewController:viewController] animated:YES completion:nil];
}

- (void)fwDebugFpsItemLongPressed:(UIGestureRecognizer *)gestureRecognizer
{
    [FWDebugManager fwDebugShowPrompt:self.explorerViewController security:NO title:@"Input Value" message:nil text:nil block:^(BOOL confirm, NSString *text) {
        if (text.length < 1) return;
        if ([FWDebugManager sharedInstance].openUrl && [FWDebugManager sharedInstance].openUrl(text)) return;
        
        NSURL *url = [[NSURL alloc] initWithString:text];
        if (url != nil && url.scheme != nil) {
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            } else {
                [[UIApplication sharedApplication] openURL:url];
            }
            return;
        }
        
        Class clazz = NSClassFromString(text);
        if (clazz != NULL) {
            FLEXObjectExplorerViewController *viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:clazz];
            [self.explorerViewController presentViewController:[FLEXNavigationController withRootViewController:viewController] animated:YES completion:nil];
        }
    }];
}

- (UIViewController *)fwDebugViewController
{
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if ([keyWindow isKindOfClass:[FLEXWindow class]]) {
        keyWindow = ((FLEXWindow *)keyWindow).previousKeyWindow;
    }
    UIViewController *currentViewController = keyWindow.rootViewController;
    while ([currentViewController presentedViewController]) {
        currentViewController = [currentViewController presentedViewController];
    }
    while ([currentViewController isKindOfClass:[UITabBarController class]] &&
           [(UITabBarController *)currentViewController selectedViewController]) {
        currentViewController = [(UITabBarController *)currentViewController selectedViewController];
    }
    while ([currentViewController isKindOfClass:[UINavigationController class]] &&
           [(UINavigationController *)currentViewController topViewController]) {
        currentViewController = [(UINavigationController*)currentViewController topViewController];
    }
    return currentViewController;
}

@end
