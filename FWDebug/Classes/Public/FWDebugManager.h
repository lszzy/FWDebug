//
//  FWDebugManager.h
//  FWDebug
//
//  Created by 吴勇 on 17/2/26.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 调试管理器
 */
@interface FWDebugManager : NSObject

/// 是否启用5秒内摇一摇两次切换调试器，默认YES
@property (nonatomic, assign) BOOL shakeEnabled;

/// 是否启用5秒内3指点击两次切换调试器，默认YES
@property (nonatomic, assign) BOOL touchEnabled;

/// 调试器是否隐藏
@property (nonatomic, readonly) BOOL isHidden;

/// 自定义崩溃上报者，支持url或逗号分隔email，配置后生效，默认记录文件
@property (nonatomic, copy, nullable) NSString *crashReporter;

/// 打开URL调试钩子方法，长按帧率按钮触发
@property (nonatomic, copy, nullable) BOOL (^openUrl)(NSString *url);

/// 单例模式
+ (instancetype)sharedInstance;

/// 注册自定义入口，点击时打开objectBlock返回值，支持控制器、文件路径和任意对象
- (void)registerEntry:(NSString *)entryName objectBlock:(id (^)(void))objectBlock;

/// 注册自定义入口，点击时触发actionBlock，参数为调试控制器
- (void)registerEntry:(NSString *)entryName actionBlock:(void (^)(__kindof UITableViewController *))actionBlock;

/// 移除自定义入口
- (void)removeEntry:(NSString *)entryName;

/// 记录自定义事件，object为事件对象，userInfo为weak引用附加信息
- (void)recordEvent:(NSString *)event object:(id)object userInfo:(nullable id)userInfo;

/// 记录自定义日志到文件，从Custom Log入口可查看
- (void)log:(NSString *)message;

/// 切换调试器
- (void)toggle;

/// 显示调试器
- (void)show;

/// 隐藏调试器
- (void)hide;

@end

NS_ASSUME_NONNULL_END
