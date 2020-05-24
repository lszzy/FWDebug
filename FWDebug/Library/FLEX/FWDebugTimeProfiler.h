//
//  FWDebugTimeProfiler.h
//  FWDebug
//
//  Created by wuyong on 2020/5/18.
//  Copyright © 2020 wuyong.site. All rights reserved.
//

#import "FLEXTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FWDebugTimeProfiler : FLEXTableViewController

- (instancetype)initWithObject:(id)object;

+ (void)enableTraceVCLife;

+ (void)enableTraceVCRequest;

+ (double)currentTime;

+ (NSTimeInterval)appLaunchedTime;

+ (void)recordEvent:(NSString *)event object:(id)object userInfo:(nullable id)userInfo;

@end

NS_ASSUME_NONNULL_END
