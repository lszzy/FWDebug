//
//  ViewController.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "ViewController.h"
#import <FWDebug/FWDebug.h>

@interface ViewController ()

@property (nonatomic, strong) id object;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Example";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Debug" style:UIBarButtonItemStylePlain target:self action:@selector(onDebug)];
    self.navigationItem.rightBarButtonItem = item;
    
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
    ViewController *retainObject = [[ViewController alloc] init];
    retainObject.object = self;
    self.object = retainObject;
}

- (void)onCrash {
    id object = [[NSObject alloc] init];
    [object onCrash];
}

@end
