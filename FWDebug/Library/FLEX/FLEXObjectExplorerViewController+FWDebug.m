//
//  FLEXObjectExplorerViewController+FWDebugFLEX.m
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FLEXObjectExplorerViewController+FWDebug.h"
#import "FLEXObjectExplorerFactory.h"
#import <objc/runtime.h>

@implementation FLEXObjectExplorerViewController (FWDebug)

+ (void)load
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    method_exchangeImplementations(
        class_getInstanceMethod(self, @selector(canDrillInToRow:inExplorerSection:)),
        class_getInstanceMethod(self, @selector(fwDebugCanDrillInToRow:inExplorerSection:))
    );
    
    method_exchangeImplementations(
        class_getInstanceMethod(self, @selector(drillInViewControllerForRow:inExplorerSection:)),
        class_getInstanceMethod(self, @selector(fwDebugDrillInViewControllerForRow:inExplorerSection:))
    );
#pragma clang diagnostic pop
}

#pragma mark - FWDebug

- (BOOL)fwDebugCanDrillInToRow:(NSInteger)row inExplorerSection:(FLEXObjectExplorerSection)section
{
    if (section == FLEXObjectExplorerSectionDescription) {
        return object_getClass(self.object) != Nil;
    } else {
        return [self fwDebugCanDrillInToRow:row inExplorerSection:section];
    }
}

- (UIViewController *)fwDebugDrillInViewControllerForRow:(NSUInteger)row inExplorerSection:(FLEXObjectExplorerSection)section
{
    if (section == FLEXObjectExplorerSectionDescription) {
        UIViewController *viewController = nil;
        if (object_getClass(self.object) != Nil) {
            viewController = [FLEXObjectExplorerFactory explorerViewControllerForObject:object_getClass(self.object)];
        }
        return viewController;
    } else {
        return [self fwDebugDrillInViewControllerForRow:row inExplorerSection:section];
    }
}

@end
