//
//  FWDebugManager+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 2018/1/4.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWDebugManager.h"
#import <UIKit/UIKit.h>

/**
 * Vendor修改注释格式如下：
 *     // FWDebug
 * Vendor修改文件列表如下：
 *     FBRetainCycleDetector.h
 *     FLEXOSLogController.m
 *     GCDWebUploader.m
 *     KSSystemCapabilities.h
 * Vendor更新替换完毕后统一还原修改即可
 */
@interface FWDebugManager (FWDebug)

+ (BOOL)swizzleMethod:(SEL)originalSelector in:(Class)originalClass withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (BOOL)swizzleMethodOnce:(SEL)originalSelector in:(Class)originalClass withBlock:(id (^)(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)))block;

+ (void)showPrompt:(UIViewController *)viewController security:(BOOL)security title:(NSString *)title message:(NSString *)message text:(NSString *)text block:(void (^)(BOOL confirm, NSString *text))block;

+ (UIViewController *)topViewController;

@end
