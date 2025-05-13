//
//  FWDebugDeviceInfo.h
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FWDebugSystemInfo : FLEXTableViewController

+ (void)fwDebugLoad;

+ (void)registerEntry:(NSString *)entryName entryBlock:(NSString * _Nullable (^)(void))entryBlock;

+ (void)removeEntry:(NSString *)entryName;

@end

NS_ASSUME_NONNULL_END
