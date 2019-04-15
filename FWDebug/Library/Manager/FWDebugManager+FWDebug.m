//
//  FWDebugManager+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 2018/1/4.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FWDebugManager+FWDebug.h"
#import <objc/runtime.h>

@implementation FWDebugManager (FWDebug)

+ (BOOL)fwDebugSwizzleInstance:(Class)clazz method:(SEL)originalSelector with:(SEL)swizzleSelector
{
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(clazz, swizzleSelector);
    if (!originalMethod || !swizzleMethod) {
        return NO;
    }
    
    // 添加当前类方法实现，防止影响到父类方法
    class_addMethod(clazz, originalSelector, class_getMethodImplementation(clazz, originalSelector), method_getTypeEncoding(originalMethod));
    class_addMethod(clazz, swizzleSelector, class_getMethodImplementation(clazz, swizzleSelector), method_getTypeEncoding(swizzleMethod));
    
    method_exchangeImplementations(class_getInstanceMethod(clazz, originalSelector), class_getInstanceMethod(clazz, swizzleSelector));
    return YES;
}

+ (BOOL)fwDebugSwizzleClass:(Class)clazz method:(SEL)originalSelector with:(SEL)swizzleSelector
{
    return [self fwDebugSwizzleInstance:object_getClass((id)clazz) method:originalSelector with:swizzleSelector];
}

+ (void)fwDebugShowPrompt:(UIViewController *)viewController security:(BOOL)security title:(NSString *)title message:(NSString *)message text:(NSString *)text block:(void (^)(BOOL confirm, NSString *text))block
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = security;
        textField.text = text ?: @"";
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (block) {
            block(NO, [alertController.textFields objectAtIndex:0].text);
        }
    }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (block) {
            block(YES, [alertController.textFields objectAtIndex:0].text);
        }
    }];
    [alertController addAction:alertAction];
    
    [viewController presentViewController:alertController animated:YES completion:nil];
}

@end
