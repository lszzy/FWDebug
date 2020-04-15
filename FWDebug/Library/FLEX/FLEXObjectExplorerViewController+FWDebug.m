//
//  FLEXObjectExplorerViewController+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/23.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXObjectExplorerViewController+FWDebug.h"
#import "FLEXHeapEnumerator.h"
#import "FLEXObjectRef.h"
#import "FWDebugManager+FWDebug.h"
#import "FWDebugRetainCycle.h"
#import "FBRetainCycleDetector+FWDebug.h"
#import <malloc/malloc.h>

@implementation FLEXObjectExplorerViewController (FWDebug)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager fwDebugSwizzleInstance:self method:@selector(viewDidLoad) with:@selector(fwDebugViewDidLoad)];
    });
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
    if (self.explorer.objectIsInstance) {
        retainCycles = [FBRetainCycleDetector fwDebugRetainCycleWithObject:self.object];
    } else {
        NSString *className = NSStringFromClass(object_getClass(self.object));
        const char *classNameCString = className.UTF8String;
        NSMutableArray *instances = [NSMutableArray new];
        [FLEXHeapEnumerator enumerateLiveObjectsUsingBlock:^(__unsafe_unretained id object, __unsafe_unretained Class actualClass) {
            if (strcmp(classNameCString, class_getName(actualClass)) == 0) {
                if (malloc_size((__bridge const void *)(object)) > 0) {
                    [instances addObject:object];
                }
            }
        }];
        
        NSArray<FLEXObjectRef *> *references = [FLEXObjectRef referencingAll:instances];
        retainCycles = [FBRetainCycleDetector fwDebugRetainCycleWithObjects:references];
    }
    
    FWDebugRetainCycle *viewController = [[FWDebugRetainCycle alloc] init];
    viewController.retainCycles = [retainCycles allObjects];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
