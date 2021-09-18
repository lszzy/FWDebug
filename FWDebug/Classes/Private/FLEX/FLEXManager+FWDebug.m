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
#import "FLEXOSLogController+FWDebug.h"
#import "FWDebugSystemInfo.h"
#import "FWDebugTimeProfiler.h"
#import "FWDebugWebServer.h"
#import "FWDebugAppConfig.h"
#import "FWDebugFakeLocation.h"
#import "FWDebugFakeNotification.h"
#import <objc/runtime.h>

@implementation FLEXManager (FWDebug)

+ (void)fwDebugLoad
{
    [FLEXOSLogController fwDebugLoad];
    [FLEXExplorerToolbar fwDebugLoad];
    [FLEXFileBrowserController fwDebugLoad];
    [FLEXObjectExplorerViewController fwDebugLoad];
    [FLEXObjectListViewController fwDebugLoad];
    [FWDebugFakeLocation fwDebugLoad];
    [FWDebugTimeProfiler fwDebugLoad];
    
    [FWDebugManager swizzleMethod:@selector(showExplorer) in:[FLEXManager class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^(__unsafe_unretained FLEXManager *selfObject) {
            if ([FWDebugAppConfig isAppLocked]) return;
            
            ((void (*)(id, SEL))originalIMP())(selfObject, originalCMD);
            
            [selfObject.fwDebugFpsInfo start];
        };
    }];
    
    [FWDebugManager swizzleMethod:@selector(hideExplorer) in:[FLEXManager class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^(__unsafe_unretained FLEXManager *selfObject) {
            if ([FWDebugAppConfig isAppLocked]) return;
            
            ((void (*)(id, SEL))originalIMP())(selfObject, originalCMD);
            
            [selfObject.fwDebugFpsInfo stop];
        };
    }];
    
    if (@available(iOS 13.0, *)) {
        [FWDebugManager swizzleMethod:@selector(showExplorerFromScene:) in:[FLEXManager class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^(__unsafe_unretained FLEXManager *selfObject, UIWindowScene *scene) {
                if ([FWDebugAppConfig isAppLocked]) return;
                
                ((void (*)(id, SEL, UIWindowScene *))originalIMP())(selfObject, originalCMD, scene);
                
                [selfObject.fwDebugFpsInfo start];
            };
        }];
    }
    
    [FLEXManager sharedManager].networkDebuggingEnabled = YES;
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"💟  Device Info" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugSystemInfo alloc] init];
    }];
    
    [[FLEXManager sharedManager] registerGlobalEntryWithName:@"⏱️  Time Profiler" viewControllerFutureBlock:^UIViewController *{
        return [[FWDebugTimeProfiler alloc] init];
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
        [self.explorerViewController.explorerToolbar.fwDebugFpsItem addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(fwDebugFpsItemLongPressed:)]];
    }
    return fpsInfo;
}

- (void)fwDebugFpsInfoChanged:(FWDebugFpsData *)fpsData
{
    [self.explorerViewController.explorerToolbar.fwDebugFpsItem setFpsData:fpsData];
}

- (void)fwDebugFpsItemClicked:(FLEXExplorerToolbarItem *)sender
{
    FLEXObjectExplorerViewController *viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:[FWDebugManager topViewController]];
    [self.explorerViewController presentViewController:[FLEXNavigationController withRootViewController:viewController] animated:YES completion:nil];
}

- (void)fwDebugFpsItemLongPressed:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan) return;
    NSString *previousText = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugOpenUrl"];
    [FWDebugManager showPrompt:self.explorerViewController security:NO title:@"Input Value" message:nil text:previousText block:^(BOOL confirm, NSString *text) {
        if (!confirm || text.length < 1) return;
        
        [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugOpenUrl"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if ([FWDebugManager sharedInstance].openUrl && [FWDebugManager sharedInstance].openUrl(text)) return;
        
        NSURL *url = [[NSURL alloc] initWithString:text];
        if (url != nil && url.scheme != nil) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            return;
        }
        
        Class clazz = NSClassFromString(text);
        if (clazz == NULL) {
            NSString *module = [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey];
            if (module != nil) {
                clazz = NSClassFromString([NSString stringWithFormat:@"%@.%@", module, text]);
            }
        }
        if (clazz != NULL) {
            FLEXObjectExplorerViewController *viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:clazz];
            [self.explorerViewController presentViewController:[FLEXNavigationController withRootViewController:viewController] animated:YES completion:nil];
        }
    }];
}

@end
