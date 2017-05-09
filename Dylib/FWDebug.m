//
//  FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/3/8.
//  Copyright © 2017年 song. All rights reserved.
//

#import "FWDebug.h"

// 自动启动方法
static void __attribute__((constructor)) initialize(void)
{
    NSLog(@"FWDebug.dylib loaded");
}
