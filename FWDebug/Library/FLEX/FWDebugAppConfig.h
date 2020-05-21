//
//  FWDebugAppSecret.h
//  FWDebug
//
//  Created by wuyong on 2017/7/4.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FWDebugAppConfig : UITableViewController

+ (void)fwDebugLaunch;

+ (BOOL)isAppLocked;

+ (BOOL)filterSystemLog;

+ (BOOL)traceVCLife;

+ (NSInteger)retainCycleDepth;

@end
