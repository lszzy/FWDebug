//
//  ViewController.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "ViewController.h"
#import "ObjectivecController.h"
#import "SwiftHeader.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Example";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *objectivecButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [objectivecButton setTitle:@"Objective-C" forState:UIControlStateNormal];
    [objectivecButton addTarget:self action:@selector(onObjectivec) forControlEvents:UIControlEventTouchUpInside];
    objectivecButton.frame = CGRectMake(self.view.frame.size.width / 2 - 50, 20, 100, 30);
    [self.view addSubview:objectivecButton];
    
    UIButton *swiftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    // swiftButton.hidden = YES;
    swiftButton.hidden = YES;
    [swiftButton setTitle:@"Swift" forState:UIControlStateNormal];
    [swiftButton addTarget:self action:@selector(onSwift) forControlEvents:UIControlEventTouchUpInside];
    swiftButton.frame = CGRectMake(self.view.frame.size.width / 2 - 50, 70, 100, 30);
    [self.view addSubview:swiftButton];
}

#pragma mark - Action
- (void)onSwift {
    // SwiftController *viewController = [[SwiftController alloc] init];
    ObjectivecController *viewController = [[ObjectivecController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)onObjectivec {
    ObjectivecController *viewController = [[ObjectivecController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
