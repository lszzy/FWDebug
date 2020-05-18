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

+ (BOOL)fwDebugSwizzleMethod:(SEL)originalSelector in:(Class)originalClass with:(SEL)swizzleSelector in:(Class)swizzleClass
{
    if (!originalClass || !swizzleClass) {
        return NO;
    }
    
    Method originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(swizzleClass, swizzleSelector);
    if (!swizzleMethod) {
        return NO;
    }
    
    BOOL addMethod = class_addMethod(originalClass, originalSelector, method_getImplementation(swizzleMethod), method_getTypeEncoding(swizzleMethod));
    if (addMethod) {
        if (originalMethod) {
            class_replaceMethod(swizzleClass, swizzleSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            class_replaceMethod(swizzleClass, swizzleSelector, imp_implementationWithBlock(^(id selfObject){}), "v@:");
        }
    } else {
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
    return YES;
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
