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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Example";
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Debug" style:UIBarButtonItemStylePlain target:self action:@selector(onDebug)];
    self.navigationItem.rightBarButtonItem = item;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Crash" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(onCrash) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 100, 30);
    button.center = self.view.center;
    [self.view addSubview:button];
}

- (void)onDebug {
    [[FWDebugManager sharedInstance] show];
}

- (void)onCrash {
    id object = [[NSObject alloc] init];
    [object onCrash];
}

@end
