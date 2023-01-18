//
//  ObjectivecController.m
//  Example
//
//  Created by wuyong on 17/2/16.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "ObjectivecController.h"
#import <CoreLocation/CoreLocation.h>
#import <WebKit/WebKit.h>
#import <FWDebug/FWDebug.h>

@interface ObjectivecController () <CLLocationManagerDelegate>

@property (nonatomic, strong) UIButton *locationButton;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) UILabel *weatherLabel;

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
    
    UIButton *memoryDirtyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [memoryDirtyButton setTitle:@"Add Memory Dirty" forState:UIControlStateNormal];
    [memoryDirtyButton addTarget:self action:@selector(onMemoryDirty) forControlEvents:UIControlEventTouchUpInside];
    memoryDirtyButton.frame = CGRectMake(self.view.frame.size.width / 2 - 100, 120, 200, 30);
    [self.view addSubview:memoryDirtyButton];
    
    UIButton *webViewButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [webViewButton setTitle:@"Open WebView" forState:UIControlStateNormal];
    [webViewButton addTarget:self action:@selector(onWebView) forControlEvents:UIControlEventTouchUpInside];
    webViewButton.frame = CGRectMake(self.view.frame.size.width / 2 - 100, 170, 200, 30);
    [self.view addSubview:webViewButton];
    
    UIButton *crashButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [crashButton setTitle:@"Crash" forState:UIControlStateNormal];
    [crashButton addTarget:self action:@selector(onCrash) forControlEvents:UIControlEventTouchUpInside];
    crashButton.frame = CGRectMake(self.view.frame.size.width / 2 - 100, 220, 200, 30);
    [self.view addSubview:crashButton];
    
    UILabel *weatherLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 100, 270, 200, 30)];
    self.weatherLabel = weatherLabel;
    weatherLabel.text = @"Loading...";
    weatherLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:weatherLabel];
    
    [self onTimeTest];
    [self onRequest];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = locations.lastObject;
    //CLLocation *location = manager.location;
    [self.locationButton setTitle:[NSString stringWithFormat:@"%f,%f", location.coordinate.latitude, location.coordinate.longitude] forState:UIControlStateNormal];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self.locationButton setTitle:@"Failed" forState:UIControlStateNormal];
}

#pragma mark - Action

- (void)onTimeTest {
    NSInteger total = 0;
    for (NSInteger i = 0; i < 1000000; i++) {
        total += i;
    }
}

- (void)onRequest {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.weather.com.cn/data/sk/101040100.html"]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            id object = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
            if (object) {
                self.weatherLabel.text = [NSString stringWithFormat:@"%@: %@℃", object[@"weatherinfo"][@"city"], object[@"weatherinfo"][@"temp"]];
            } else {
                self.weatherLabel.text = @"Failed";
            }
        });
    }];
    [task resume];
}

- (void)onDebug {
    if ([FWDebugManager sharedInstance].isHidden) {
        [[FWDebugManager sharedInstance] show];
        [[FWDebugManager sharedInstance] systemLog:@"Show FWDebug"];
        [[FWDebugManager sharedInstance] customLog:@"Show FWDebug"];
    } else {
        [[FWDebugManager sharedInstance] hide];
        [[FWDebugManager sharedInstance] systemLog:@"Hide FWDebug"];
        [[FWDebugManager sharedInstance] customLog:@"Hide FWDebug"];
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

- (void)onMemoryDirty {
    char *buf = malloc(10 * 1024 * 1024 * sizeof(char));
    for (int i = 0; i < 10 * 1024 * 1024; ++i) {
        buf[i] = (char)rand();
    }
}

- (void)onWebView {
    UIViewController *webController = [[UIViewController alloc] init];
    webController.navigationItem.title = @"WKWebView";
    webController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(onWebClose)];
    webController.view.backgroundColor = UIColor.whiteColor;
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:webController.view.bounds];
    webView.allowsBackForwardNavigationGestures = YES;
    [webController.view addSubview:webView];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.wuyong.site/"]]];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:webController];
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)onWebClose {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onCrash {
    id object = [[NSObject alloc] init];
    [object onCrash];
}

@end
