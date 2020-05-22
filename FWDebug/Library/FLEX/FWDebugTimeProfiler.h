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

- (instancetype)initWithObject:(NSObject *)object;

+ (double)currentTime;

+ (NSTimeInterval)appLaunchedTime;

@end

@interface NSObject (FWDebugTimeProfiler)

- (void)fwDebugRecordEvent:(NSString *)event;

@end

NS_ASSUME_NONNULL_END
