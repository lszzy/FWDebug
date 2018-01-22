//
//  FWDebugManager.h
//  FWDebug
//
//  Created by 吴勇 on 17/2/26.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * 调试管理器
 */
@interface FWDebugManager : NSObject

// 是否启用摇一摇功能（5秒内摇一摇两次切换调试器），默认YES
@property (nonatomic, assign) BOOL shakeEnabled;

// 调试器是否隐藏
@property (nonatomic, readonly) BOOL isHidden;

// 单例方法
+ (instancetype)sharedInstance;

// 显示调试器
- (void)show;

// 隐藏调试器
- (void)hide;

@end
