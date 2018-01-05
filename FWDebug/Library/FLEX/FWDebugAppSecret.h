//
//  FWDebugAppSecret.h
//  FWDebug
//
//  Created by wuyong on 2017/7/4.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FWDebugAppSecret : UITableViewController

+ (BOOL)isAppLocked;

+ (NSInteger)retainCycleDepth;

@end
