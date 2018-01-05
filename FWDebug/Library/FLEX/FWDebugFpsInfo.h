//
//  FWDebugFpsInfo.h
//  FWDebug
//
//  Created by wuyong on 17/2/28.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FBRetainCycleDetector.h"

@interface FWDebugFpsData : NSObject

// FPS，取整数：(int)round(fps)
@property (nonatomic, assign) float fps;

// 占用内存，单位MB
@property (nonatomic, assign) float memory;

// CPU占比，0-100
@property (nonatomic, assign) float cpu;

// FPS结果，1好 0警告 -1不好
@property (nonatomic, assign) NSInteger fpsState;

// 占用内存结果，1好 0警告 -1不好
@property (nonatomic, assign) NSInteger memoryState;

// CPU占比结果，1好 0警告 -1不好
@property (nonatomic, assign) NSInteger cpuState;

// 当前视图控制器
@property (nonatomic, weak) UIViewController *currentController;

@end

@protocol FWDebugFpsInfoDelegate <NSObject>

- (void)fwDebugFpsInfoChanged:(FWDebugFpsData *)fpsData;

@end

@interface FWDebugFpsInfo : NSObject

@property (nonatomic, weak) id<FWDebugFpsInfoDelegate> delegate;

@property (nonatomic, strong, readonly) FWDebugFpsData *fpsData;

- (void)start;

- (void)stop;

@end
