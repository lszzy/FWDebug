//
//  FLEXObjectExplorerViewController+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXObjectExplorerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXObjectExplorerViewController (FWDebug)

+ (void)fwDebugLoad;

+ (void)fwDebugRegisterEntry:(NSString *)entryName title:(NSString *)title filter:(nullable BOOL (^)(id object))filter actionBlock:(void (^)(__kindof UIViewController *viewController, id object))actionBlock;

+ (void)fwDebugRemoveEntry:(NSString *)entryName;

@end

NS_ASSUME_NONNULL_END
