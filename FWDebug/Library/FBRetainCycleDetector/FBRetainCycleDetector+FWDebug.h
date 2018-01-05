//
//  FBRetainCycleDetector+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 2017/12/4.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FBRetainCycleDetector.h"

@interface FBRetainCycleDetector (FWDebug)

+ (void)fwDebugLaunch;

+ (NSSet *)fwDebugRetainCycleWithObject:(id)object;

+ (NSSet *)fwDebugRetainCycleWithObjects:(NSArray *)objects;

@end
