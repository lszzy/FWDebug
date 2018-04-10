//
//  ObjectivecController.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "ObjectivecController.h"
#import <FWDebug/FWDebug.h>

@interface ObjectivecController ()

@property (nonatomic, strong) id object;

@end

@implementation ObjectivecController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Objective-C";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Debug" style:UIBarButtonItemStylePlain target:self action:@selector(onDebug)];
    
    UIButton *retainCycleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [retainCycleButton setTitle:@"Retain Cycle" forState:UIControlStateNormal];
    [retainCycleButton addTarget:self action:@selector(onRetainCycle) forControlEvents:UIControlEventTouchUpInside];
    retainCycleButton.frame = CGRectMake(self.view.frame.size.width / 2 - 50, 20, 100, 30);
    [self.view addSubview:retainCycleButton];
    
    UIButton *crashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [crashButton setTitle:@"Crash" forState:UIControlStateNormal];
    [crashButton addTarget:self action:@selector(onCrash) forControlEvents:UIControlEventTouchUpInside];
    crashButton.frame = CGRectMake(self.view.frame.size.width / 2 - 50, 70, 100, 30);
    [self.view addSubview:crashButton];
}

#pragma mark - Action
- (void)onDebug {
    if ([FWDebugManager sharedInstance].isHidden) {
        [[FWDebugManager sharedInstance] show];
        NSLog(@"Show FWDebug");
    } else {
        [[FWDebugManager sharedInstance] hide];
        NSLog(@"Hide FWDebug");
    }
}

- (void)onRetainCycle {
    ObjectivecController *retainObject = [[ObjectivecController alloc] init];
    retainObject.object = self;
    self.object = retainObject;
}

- (void)onCrash {
    id object = [[NSObject alloc] init];
    [object onCrash];
}

@end

