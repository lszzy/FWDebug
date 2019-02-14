//
//  FLEXObjectExplorerViewController+FWDebugFLEX.m
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXObjectExplorerViewController+FWDebug.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXInstancesTableViewController.h"
#import "FLEXHeapEnumerator.h"
#import "FLEXObjectRef.h"
#import "FWDebugRetainCycle.h"
#import "FWDebugManager+FWDebug.h"
#import "FBRetainCycleDetector+FWDebug.h"
#import <objc/runtime.h>

@interface FLEXInstancesTableViewController ()

@property (nonatomic) NSArray<FLEXObjectRef *> *instances;

@end

@implementation FLEXObjectExplorerViewController (FWDebug)

+ (void)load
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager fwDebugSwizzleInstance:self method:@selector(viewDidLoad) with:@selector(fwDebugViewDidLoad)];
        [FWDebugManager fwDebugSwizzleInstance:self method:@selector(canDrillInToRow:inExplorerSection:) with:@selector(fwDebugCanDrillInToRow:inExplorerSection:)];
        [FWDebugManager fwDebugSwizzleInstance:self method:@selector(drillInViewControllerForRow:inExplorerSection:) with:@selector(fwDebugDrillInViewControllerForRow:inExplorerSection:)];
    });
#pragma clang diagnostic pop
}

#pragma mark - FWDebug

- (void)fwDebugViewDidLoad
{
    [self fwDebugViewDidLoad];
    
    UIBarButtonItem *retainItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(fwDebugRetainCycles)];
    if (self.navigationItem.rightBarButtonItems.count > 0) {
        NSMutableArray *rightItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
        [rightItems addObject:retainItem];
        self.navigationItem.rightBarButtonItems = rightItems;
    } else {
        self.navigationItem.rightBarButtonItem = retainItem;
    }
}

- (void)fwDebugRetainCycles
{
    NSSet *retainCycles = nil;
    if (!class_isMetaClass(object_getClass(self.object))) {
        retainCycles = [FBRetainCycleDetector fwDebugRetainCycleWithObject:self.object];
    } else {
        FLEXInstancesTableViewController *tempObject = [FLEXInstancesTableViewController instancesTableViewControllerForClassName:NSStringFromClass(object_getClass(self.object))];
        retainCycles = [FBRetainCycleDetector fwDebugRetainCycleWithObjects:tempObject.instances];
    }
    
    FWDebugRetainCycle *viewController = [[FWDebugRetainCycle alloc] init];
    viewController.retainCycles = [retainCycles allObjects];
    [self.navigationController pushViewController:viewController animated:YES];
}

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
