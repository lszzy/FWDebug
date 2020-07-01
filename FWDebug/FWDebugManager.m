//
//  FWDebugManager.m
//  FWDebug
//
//  Created by 吴勇 on 17/2/26.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugManager.h"
#import <UIKit/UIKit.h>
#import "FWDebugManager+FWDebug.h"
#import "FLEXManager+FWDebug.h"
#import "KSCrash+FWDebug.h"
#import "FBRetainCycleDetector+FWDebug.h"
#import "FWDebugTimeProfiler.h"

NSString * const FWDebugShakeNotification = @"FWDebugShakeNotification";

@interface FWDebugManager ()

@property (nonatomic, strong) NSDate *shakeDate;

@end

@implementation FWDebugManager

#pragma mark - Lifecycle

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager swizzleMethod:@selector(sendEvent:) in:[UIApplication class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^(__unsafe_unretained UIApplication *selfObject, UIEvent *event) {
                ((void (*)(id, SEL, UIEvent *))originalIMP())(selfObject, originalCMD, event);
                
                if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:FWDebugShakeNotification object:event];
                }
            };
        }];
        
        [[FWDebugManager sharedInstance] onLoad];
    });
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
        _shakeEnabled = YES;
        
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
    [FLEXManager fwDebugLaunch];
    [FBRetainCycleDetector fwDebugLaunch];
    [KSCrash fwDebugLaunch];
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

- (void)recordEvent:(NSString *)event object:(id)object userInfo:(id)userInfo
{
    [FWDebugTimeProfiler recordEvent:event object:object userInfo:userInfo];
}

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
