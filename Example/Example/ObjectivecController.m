//
//  ObjectivecController.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "ObjectivecController.h"
#import <CoreLocation/CoreLocation.h>
#import <FWDebug/FWDebug.h>

@interface ObjectivecController () <CLLocationManagerDelegate>

@property (nonatomic, strong) UIButton *locationButton;
@property (nonatomic, strong) CLLocationManager *locationManager;

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
    retainCycleButton.frame = CGRectMake(self.view.frame.size.width / 2 - 100, 20, 200, 30);
    [self.view addSubview:retainCycleButton];
    
    UIButton *fakeLocationButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.locationButton = fakeLocationButton;
    [fakeLocationButton setTitle:@"Fake Location" forState:UIControlStateNormal];
    [fakeLocationButton addTarget:self action:@selector(onFakeLocation) forControlEvents:UIControlEventTouchUpInside];
    fakeLocationButton.frame = CGRectMake(self.view.frame.size.width / 2 - 100, 70, 200, 30);
    [self.view addSubview:fakeLocationButton];
    
    UIButton *crashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [crashButton setTitle:@"Crash" forState:UIControlStateNormal];
    [crashButton addTarget:self action:@selector(onCrash) forControlEvents:UIControlEventTouchUpInside];
    crashButton.frame = CGRectMake(self.view.frame.size.width / 2 - 100, 120, 200, 30);
    [self.view addSubview:crashButton];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *location = locations.lastObject;
    //CLLocation *location = manager.location;
    [self.locationButton setTitle:[NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude] forState:UIControlStateNormal];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self.locationButton setTitle:@"Failed" forState:UIControlStateNormal];
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

- (void)onFakeLocation {
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager startUpdatingLocation];
        [self.locationButton setTitle:@"Updating" forState:UIControlStateNormal];
    } else {
        [self.locationManager stopUpdatingLocation];
        self.locationManager.delegate = nil;
        self.locationManager = nil;
        [self.locationButton setTitle:@"Fake Location" forState:UIControlStateNormal];
    }
}

- (void)onCrash {
    id object = [[NSObject alloc] init];
    [object onCrash];
}

@end

