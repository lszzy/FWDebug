//
//  FWDebugManager.m
//  FWDebug
//
//  Created by 吴勇 on 17/2/26.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugManager.h"
#import "FWDebugManager+FWDebug.h"
#import "FLEXManager+FWDebug.h"
#import "KSCrash+FWDebug.h"
#import "FBRetainCycleDetector+FWDebug.h"
#import "FWDebugTimeProfiler.h"
#import <UIKit/UIKit.h>

NSString * const FWDebugEventNotification = @"FWDebugEventNotification";

@interface FWDebugManager ()

@property (nonatomic, strong) NSDate *eventDate;

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
                
                if ([FWDebugManager sharedInstance].shakeEnabled) {
                    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:FWDebugEventNotification object:event];
                    }
                }
                
                if ([FWDebugManager sharedInstance].touchEnabled) {
                    if (event.type == UIEventTypeTouches && event.subtype == UIEventSubtypeNone && event.allTouches.count == 5) {
                        [event.allTouches enumerateObjectsUsingBlock:^(UITouch *obj, BOOL *stop) {
                            if (obj.phase == UITouchPhaseEnded) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:FWDebugEventNotification object:event];
                                *stop = YES;
                            }
                        }];
                    }
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
        _touchEnabled = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLaunch:) name:UIApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onEvent:) name:FWDebugEventNotification object:nil];
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

- (void)onEvent:(NSNotification *)notification
{
    if (self.eventDate && fabs([self.eventDate timeIntervalSinceNow]) > 1.0 && fabs([self.eventDate timeIntervalSinceNow]) < 5.0) {
        [[FLEXManager sharedManager] toggleExplorer];
        self.eventDate = nil;
    } else if (!self.eventDate || fabs([self.eventDate timeIntervalSinceNow]) > 5.0) {
        self.eventDate = [NSDate date];
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

- (void)toggle
{
    [[FLEXManager sharedManager] toggleExplorer];
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
