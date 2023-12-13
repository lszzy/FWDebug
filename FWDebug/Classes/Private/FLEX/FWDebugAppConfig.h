//
//  FWDebugAppSecret.h
//  FWDebug
//
//  Created by wuyong on 2017/7/4.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXTableViewController.h"

@interface FWDebugAppConfig : FLEXTableViewController

+ (void)fwDebugLoad;

+ (void)fwDebugLaunch;

+ (BOOL)isAppLocked;

+ (BOOL)filterSystemLog;

+ (BOOL)hookSystemLog;

+ (BOOL)traceVCLife;

+ (BOOL)traceVCRequest;

+ (NSString *)traceVCUrls;

+ (NSInteger)retainCycleDepth;

+ (void)webViewInjectJavascript;

+ (void)logFile:(NSString *)message;

@end
