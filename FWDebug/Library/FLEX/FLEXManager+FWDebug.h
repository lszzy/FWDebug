//
//  FLEXManager+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 17/2/28.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXManager.h"
#import "FWDebugFpsInfo.h"

/**
 * Vendor/FLEX修改如下：
 * FLEXHeapEnumerator.m(92): #if __arm64__
 * 修改为: #if __arm64__ || __x86_64__
 * 修正模拟器Heap Objects为空问题
 * (执行clang -dM -E -x c /dev/null获取宏列表)
 */
@interface FLEXManager (FWDebug) <FWDebugFpsInfoDelegate>

+ (void)fwDebugLoad;

@end
