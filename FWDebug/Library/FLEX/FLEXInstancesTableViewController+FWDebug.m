//
//  FLEXInstancesTableViewController+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 2018/1/4.
//  Copyright © 2018年 wuyong.site. All rights reserved.
//

#import "FLEXInstancesTableViewController+FWDebug.h"
#import "FWDebugManager+FWDebug.h"
#import "FBRetainCycleDetector+FWDebug.h"
#import "FWDebugRetainCycle.h"

@interface FLEXInstancesTableViewController ()

@property (nonatomic, strong) NSArray *instances;

@end

@implementation FLEXInstancesTableViewController (FWDebug)

+ (void)load
{
    [FWDebugManager fwDebugSwizzleInstance:self method:@selector(viewDidLoad) with:@selector(fwDebugViewDidLoad)];
}

#pragma mark - FWDebug

- (void)fwDebugViewDidLoad
{
    [self fwDebugViewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(fwDebugRetainCycles)];
}

- (void)fwDebugRetainCycles
{
    NSSet *retainCycles = [FBRetainCycleDetector fwDebugRetainCycleWithObjects:self.instances];
    FWDebugRetainCycle *viewController = [[FWDebugRetainCycle alloc] init];
    viewController.retainCycles = [retainCycles allObjects];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
