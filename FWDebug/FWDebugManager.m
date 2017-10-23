//
//  FWDebugManager.m
//  FWDebug
//
//  Created by 吴勇 on 17/2/26.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FWDebugManager.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "FLEXManager+FWDebug.h"
#import "KSCrash+FWDebug.h"

#pragma mark - UIApplication+FWDebug

NSString * const FWDebugShakeNotification = @"FWDebugShakeNotification";

// UIApplication分类，发送摇一摇通知
@interface UIApplication (FWDebug)

@end

@implementation UIApplication (FWDebug)

+ (void)load
{
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(sendEvent:)),
                                   class_getInstanceMethod(self, @selector(fwInnerSendEvent:))
                                   );
}

- (void)fwInnerSendEvent:(UIEvent *)event
{
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FWDebugShakeNotification object:event];
    }
    
    [self fwInnerSendEvent:event];
}

@end

#pragma mark - FWDebugManager

@interface FWDebugManager ()

@property (nonatomic, strong) NSDate *shakeDate;

@end

@implementation FWDebugManager

#pragma mark - Lifecycle

+ (void)load
{
    [FWDebugManager sharedInstance];
}

+ (instancetype)sharedInstance
{
    static FWDebugManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[FWDebugManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.shakeEnabled = YES;
        
        [self onLoad];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLaunch:) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onShake:) name:FWDebugShakeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private

- (void)onLoad
{
    [FLEXManager fwDebugLoad];
}

- (void)onLaunch:(NSNotification *)notification
{
    [KSCrash fwDebugLoad];
}

- (void)onShake:(NSNotification *)notification
{
    if (self.shakeDate && fabs([self.shakeDate timeIntervalSinceNow]) > 1.0 && fabs([self.shakeDate timeIntervalSinceNow]) < 5.0) {
        if (self.shakeEnabled) {
            [[FLEXManager sharedManager] toggleExplorer];
        }
        
        self.shakeDate = nil;
    } else if (!self.shakeDate || fabs([self.shakeDate timeIntervalSinceNow]) > 5.0) {
        self.shakeDate = [NSDate date];
    }
}

#pragma mark - Public

- (BOOL)isHidden
{
    return [FLEXManager sharedManager].isHidden;
}

- (void)show
{
    [[FLEXManager sharedManager] showExplorer];
}

- (void)hide
{
    [[FLEXManager sharedManager] hideExplorer];
}

@end
