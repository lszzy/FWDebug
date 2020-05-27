//
//  FLEXInstancesTableViewController+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 2018/1/4.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FLEXObjectListViewController+FWDebug.h"
#import "FWDebugManager+FWDebug.h"
#import "FBRetainCycleDetector+FWDebug.h"
#import "FWDebugRetainCycle.h"
#import "FLEXObjectRef.h"

@interface FLEXObjectListViewController ()

@property (nonatomic, readonly) NSArray<FLEXObjectRef *> *references;

@end

@implementation FLEXObjectListViewController (FWDebug)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager swizzleMethod:@selector(viewDidLoad) in:[FLEXObjectListViewController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
            return ^(FLEXObjectListViewController *selfObject) {
                ((void (*)(id, SEL))originalIMP())(selfObject, originalCMD);
                
                [selfObject fwDebugSearchItem];
            };
        }];
    });
}

#pragma mark - FWDebug

- (void)fwDebugSearchItem
{
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
    NSSet *retainCycles = [FBRetainCycleDetector fwDebugRetainCycleWithObjects:self.references];
    FWDebugRetainCycle *viewController = [[FWDebugRetainCycle alloc] init];
    viewController.retainCycles = [retainCycles allObjects];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
