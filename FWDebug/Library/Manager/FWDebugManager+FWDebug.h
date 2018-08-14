//
//  FWDebugManager+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 2018/1/4.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWDebugManager.h"

/**
 * Vendor修改注释格式如下：
 *     // FWDebug
 * Vendor修改文件列表如下：
 *     FBRetainCycleDetector.h
 *     FLEXHeapEnumerator.m
 * Vendor更新替换完毕后统一还原修改即可
 */
@interface FWDebugManager (FWDebug)

+ (BOOL)fwDebugSwizzleInstance:(Class)clazz method:(SEL)originalSelector with:(SEL)swizzleSelector;

+ (BOOL)fwDebugSwizzleClass:(Class)clazz method:(SEL)originalSelector with:(SEL)swizzleSelector;

@end
