//
//  FWDebugManager+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 2018/1/4.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWDebugManager.h"

@interface FWDebugManager (FWDebug)

+ (BOOL)fwDebugSwizzleInstance:(Class)clazz method:(SEL)originalSelector with:(SEL)swizzleSelector;

+ (BOOL)fwDebugSwizzleClass:(Class)clazz method:(SEL)originalSelector with:(SEL)swizzleSelector;

@end
