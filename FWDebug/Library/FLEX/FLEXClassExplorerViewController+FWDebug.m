//
//  FLEXClassExplorerViewController+FWDebugFLEX.m
//  FWDebug
//
//  Created by wuyong on 17/2/24.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FLEXClassExplorerViewController+FWDebug.h"
#import <objc/runtime.h>
#import "FWDebugRuntimeBrowser.h"
#import "RTBClass.h"

@implementation FLEXClassExplorerViewController (FWDebug)

+ (void)load
{
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(customSectionTitle)),
                                   class_getInstanceMethod(self, @selector(fwDebugCustomSectionTitle))
                                   );
    
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(customSectionRowCookies)),
                                   class_getInstanceMethod(self, @selector(fwDebugCustomSectionRowCookies))
                                   );
    
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(customSectionTitleForRowCookie:)),
                                   class_getInstanceMethod(self, @selector(fwDebugCustomSectionTitleForRowCookie:))
                                   );
    
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(customSectionSubtitleForRowCookie:)),
                                   class_getInstanceMethod(self, @selector(fwDebugCustomSectionSubtitleForRowCookie:))
                                   );
    
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(customSectionCanDrillIntoRowWithCookie:)),
                                   class_getInstanceMethod(self, @selector(fwDebugCustomSectionCanDrillIntoRowWithCookie:))
                                   );
    
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(customSectionDrillInViewControllerForRowCookie:)),
                                   class_getInstanceMethod(self, @selector(fwDebugCustomSectionDrillInViewControllerForRowCookie:))
                                   );
}

#pragma mark - FWDebug

- (Class)fwDebugClass
{
    Class theClass = Nil;
    if (class_isMetaClass(object_getClass(self.object))) {
        theClass = self.object;
    }
    return theClass;
}

- (NSArray *)fwDebugClassProtocols
{
    NSArray *classProtocols = objc_getAssociatedObject(self, _cmd);
    if (!classProtocols) {
        RTBClass *classStub = [RTBClass classStubWithClass:self.fwDebugClass];
        classProtocols = [classStub sortedProtocolsNames];
        objc_setAssociatedObject(self, _cmd, classProtocols, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return classProtocols;
}

- (NSString *)fwDebugCustomSectionTitle
{
    return [self fwDebugCustomSectionTitle];
}

- (NSArray *)fwDebugCustomSectionRowCookies
{
    NSMutableArray *cookies = [NSMutableArray arrayWithArray:[self fwDebugCustomSectionRowCookies]];
    if (self.fwDebugClass) {
        [cookies addObject:@""];
    }
    if (self.fwDebugClassProtocols.count > 0) {
        [cookies addObjectsFromArray:self.fwDebugClassProtocols];
    }
    return cookies;
}

- (NSString *)fwDebugCustomSectionTitleForRowCookie:(id)rowCookie
{
    if ([rowCookie isKindOfClass:[NSString class]]) {
        if ([(NSString *)rowCookie length] == 0) {
            return [self.fwDebugClass description];
        } else {
            return [NSString stringWithFormat:@"<%@>", rowCookie];
        }
    } else {
        return [self fwDebugCustomSectionTitleForRowCookie:rowCookie];
    }
}

- (NSString *)fwDebugCustomSectionSubtitleForRowCookie:(id)rowCookie
{
    if ([rowCookie isKindOfClass:[NSString class]]) {
        if ([(NSString *)rowCookie length] == 0) {
            return [NSString stringWithFormat:@"%@.h", [self.fwDebugClass description]];
        } else {
            return [NSString stringWithFormat:@"%@.h", rowCookie];
        }
    } else {
        return [self fwDebugCustomSectionSubtitleForRowCookie:rowCookie];
    }
}

- (BOOL)fwDebugCustomSectionCanDrillIntoRowWithCookie:(id)rowCookie
{
    if ([rowCookie isKindOfClass:[NSString class]]) {
        return YES;
    } else {
        return [self fwDebugCustomSectionCanDrillIntoRowWithCookie:rowCookie];
    }
}

- (UIViewController *)fwDebugCustomSectionDrillInViewControllerForRowCookie:(id)rowCookie
{
    if ([rowCookie isKindOfClass:[NSString class]]) {
        if ([(NSString *)rowCookie length] == 0) {
            return [[FWDebugRuntimeBrowser alloc] initWithClassName:[self.fwDebugClass description]];
        } else {
            return [[FWDebugRuntimeBrowser alloc] initWithProtocolName:rowCookie];
        }
    } else {
        return [self fwDebugCustomSectionDrillInViewControllerForRowCookie:rowCookie];
    }
}

@end
