//
//  FWDebugFakeLocation.m
//  FWDebug
//
//  Created by wuyong on 2017/7/4.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FWDebugFakeLocation.h"
#import "FWDebugManager+FWDebug.h"
#import <objc/runtime.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#define FWDebugCurrentSubtitle @"Current Location"
#define FWDebugDestinationSubtitle @"Destination Location"
#define FWDebugTouchSubtitle @"Touch Location"

#pragma mark - FWDebugFakeLocation

@interface FWDebugFakeLocation () <MKMapViewDelegate>

@property (nonatomic, strong) MKMapView *mapView;

+ (CLLocation *)currentLocation;
+ (CLLocation *)destinationLocation;
+ (NSInteger)travelingTime;

@end

#pragma mark - FWDebugFakeTarget

@interface FWDebugFakeTarget : NSObject

@property (nonatomic, weak) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, strong) CLLocation *currentLocation;
@property (nonatomic, strong) CLLocation *destinationLocation;
@property (nonatomic, assign) NSInteger travelingTime;
@property (nonatomic, assign) NSInteger currentTime;
@property (nonatomic, strong) NSTimer *timer;

- (void)startUpdateLocation;
- (void)stopUpdateLocation;

@end

@implementation FWDebugFakeTarget

- (void)dealloc
{
    [self stopUpdateLocation];
}

- (void)setLocation:(CLLocation *)location
{
    if (!location) {
        return;
    }
    
    CLLocation *oldLocation = _location;
    _location = location;
    
    if (!self.locationManager || !self.locationManager.delegate) {
        return;
    }
    
    if ([self.locationManager.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.locationManager.delegate locationManager:self.locationManager didUpdateLocations:@[location]];
        });
    } else if ([self.locationManager.delegate respondsToSelector:@selector(locationManager:didUpdateToLocation:fromLocation:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [self.locationManager.delegate locationManager:self.locationManager didUpdateToLocation:location fromLocation:oldLocation];
#pragma clang diagnostic pop
        });
    }
}

- (void)startUpdateLocation
{
    [self stopUpdateLocation];
    
    self.currentLocation = [FWDebugFakeLocation currentLocation];
    self.destinationLocation = [FWDebugFakeLocation destinationLocation];
    self.travelingTime = [FWDebugFakeLocation travelingTime];
    if (!self.currentLocation) {
        return;
    }
    
    self.location = [self.currentLocation copy];
    
    if (self.destinationLocation && self.travelingTime > 0) {
        self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateLocation) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    }
}

- (void)updateLocation
{
    self.currentTime++;

    if (self.currentTime > self.travelingTime) {
        [self stopUpdateLocation];
        return;
    }
    
    if (self.currentTime < self.travelingTime) {
        double latitude = self.currentLocation.coordinate.latitude + (self.destinationLocation.coordinate.latitude - self.currentLocation.coordinate.latitude) / self.travelingTime * self.currentTime;
        double longitude = self.currentLocation.coordinate.longitude + (self.destinationLocation.coordinate.longitude - self.currentLocation.coordinate.longitude) / self.travelingTime * self.currentTime;
        self.location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    } else {
        self.location = [self.destinationLocation copy];
    }
}

- (void)stopUpdateLocation
{
    [self.timer invalidate];
    self.timer = nil;
    self.currentLocation = nil;
    self.destinationLocation = nil;
    self.travelingTime = 0;
    self.currentTime = 0;
}

@end

#pragma mark - CLLocationManager

@interface CLLocationManager (FWDebug)

@end

@implementation CLLocationManager (FWDebug)

+ (void)load
{
    if ([self fwDebugFakeEnabled]) {
        [self fwDebugFakeLocation];
    }
}

+ (BOOL)fwDebugFakeEnabled
{
    NSNumber *fakeEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeLocation"];
    return fakeEnabled ? [fakeEnabled boolValue] : NO;
}

+ (void)fwDebugFakeLocation
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [FWDebugManager fwDebugSwizzleInstance:self method:@selector(startUpdatingLocation) with:@selector(fwDebugStartUpdatingLocation)];
        [FWDebugManager fwDebugSwizzleInstance:self method:@selector(stopUpdatingLocation) with:@selector(fwDebugStopUpdatingLocation)];
        [FWDebugManager fwDebugSwizzleInstance:self method:@selector(location) with:@selector(fwDebugLocation)];
    });
}

#pragma mark - Swizzle

- (void)fwDebugStartUpdatingLocation
{
    if (![CLLocationManager fwDebugFakeEnabled]) {
        [self fwDebugStartUpdatingLocation];
        return;
    }
    [self.fwDebugFakeTarget startUpdateLocation];
}

- (void)fwDebugStopUpdatingLocation
{
    if (![CLLocationManager fwDebugFakeEnabled]) {
        [self fwDebugStopUpdatingLocation];
        return;
    }
    [self.fwDebugFakeTarget stopUpdateLocation];
}

- (CLLocation *)fwDebugLocation
{
    if (![CLLocationManager fwDebugFakeEnabled]) {
        return [self fwDebugLocation];
    }
    return self.fwDebugFakeTarget.location;
}

- (FWDebugFakeTarget *)fwDebugFakeTarget
{
    FWDebugFakeTarget *target = objc_getAssociatedObject(self, _cmd);
    if (!target) {
        target = [[FWDebugFakeTarget alloc] init];
        target.locationManager = self;
        objc_setAssociatedObject(self, _cmd, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return target;
}

@end

#pragma mark - FWDebugFakeLocation

@implementation FWDebugFakeLocation

#pragma mark - Static

+ (NSString *)currentLocationString
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeLocationCurrent"];
}

+ (CLLocation *)currentLocation
{
    NSArray *coordArray = [[self currentLocationString] componentsSeparatedByString:@","];
    if (!coordArray || coordArray.count != 2) {
        return nil;
    }
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[coordArray[0] doubleValue] longitude:[coordArray[1] doubleValue]];
    return location;
}

+ (NSString *)destinationLocationString
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeLocationDestination"];
}

+ (CLLocation *)destinationLocation
{
    NSArray *coordArray = [[self destinationLocationString] componentsSeparatedByString:@","];
    if (!coordArray || coordArray.count != 2) {
        return nil;
    }
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[coordArray[0] doubleValue] longitude:[coordArray[1] doubleValue]];
    return location;
}

+ (NSInteger)travelingTime
{
    NSString *locationTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"FWDebugFakeLocationTime"];
    return locationTime.length > 0 ? [locationTime integerValue] : 0;
}

+ (void)showPrompt:(UIViewController *)viewController title:(NSString *)title message:(NSString *)message text:(NSString *)text block:(void (^)(BOOL confirm, NSString *text))block
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = NO;
        textField.keyboardType = UIKeyboardTypePhonePad;
        textField.text = text ?: @"";
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (block) {
            block(NO, [alertController.textFields objectAtIndex:0].text);
        }
    }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *alertAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (block) {
            block(YES, [alertController.textFields objectAtIndex:0].text);
        }
    }];
    [alertController addAction:alertAction];
    
    [viewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Fake Location";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 2 ? 200 : 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 1 : (section == 1 ? 3 : 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 0 ? @"Fake Location" : (section == 1 ? @"Fake Config" : @"Fake View");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FakeLocationCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FakeLocationCell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont systemFontOfSize:14];
    }
    
    if (indexPath.section == 0) {
        UISwitch *accessoryView = [[UISwitch alloc] initWithFrame:CGRectZero];
        accessoryView.userInteractionEnabled = NO;
        cell.accessoryView = accessoryView;
        
        [self configSwitch:cell indexPath:indexPath];
    } else if (indexPath.section == 1) {
        UILabel *accessoryView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
        accessoryView.font = [UIFont systemFontOfSize:14];
        accessoryView.textColor = [UIColor blackColor];
        accessoryView.textAlignment = NSTextAlignmentRight;
        cell.accessoryView = accessoryView;
        
        [self configLabel:cell indexPath:indexPath];
    } else if (indexPath.section == 2) {
        self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200)];
        self.mapView.delegate = self;
        self.mapView.showsUserLocation = YES;
        self.mapView.userInteractionEnabled = YES;
        self.mapView.userTrackingMode = MKUserTrackingModeFollowWithHeading;
        [cell.contentView addSubview:self.mapView];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionMap:)];
        [self.mapView addGestureRecognizer:gesture];
        
        [self configMap];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        [self actionSwitch:indexPath];
    } else if (indexPath.section == 1) {
        [self actionLabel:indexPath];
    }
}

#pragma mark - Private

- (void)configSwitch:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    if ([CLLocationManager fwDebugFakeEnabled]) {
        cell.textLabel.text = @"Fake Enabled";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = YES;
    } else {
        cell.textLabel.text = @"Fake Disabled";
        cell.detailTextLabel.text = nil;
        cellSwitch.on = NO;
    }
}

- (void)configLabel:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    UILabel *cellLabel = (UILabel *)cell.accessoryView;
    cell.detailTextLabel.text = nil;
    if (indexPath.row == 0) {
        cell.textLabel.text = FWDebugCurrentSubtitle;
        NSString *locationString = [FWDebugFakeLocation currentLocationString];
        cellLabel.text = locationString.length > 0 ? locationString : @"click the map to copy";
        cellLabel.textColor = locationString.length > 0 ? [UIColor blackColor] : [UIColor grayColor];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = FWDebugDestinationSubtitle;
        NSString *locationString = [FWDebugFakeLocation destinationLocationString];
        cellLabel.text = locationString.length > 0 ? locationString : @"click the map to copy";
        cellLabel.textColor = locationString.length > 0 ? [UIColor blackColor] : [UIColor grayColor];
    } else {
        cell.textLabel.text = @"Traveling Time";
        NSInteger travelingTime = [FWDebugFakeLocation travelingTime];
        cellLabel.text = travelingTime > 0 ? [NSString stringWithFormat:@"%@", @(travelingTime)] : @"";
    }
}

- (void)configMap
{
    CLLocation *currentLocation = [FWDebugFakeLocation currentLocation];
    if (currentLocation) {
        MKPointAnnotation *currentAnnotation = [self getAnnotation:FWDebugCurrentSubtitle alreadyExist:NO];
        currentAnnotation.coordinate = currentLocation.coordinate;
        currentAnnotation.title = [NSString stringWithFormat:@"%f,%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
    } else {
        MKPointAnnotation *currentAnnotation = [self getAnnotation:FWDebugCurrentSubtitle alreadyExist:YES];
        if (currentAnnotation) {
            [self.mapView removeAnnotation:currentAnnotation];
        }
    }
    
    CLLocation *destinationLocation = [FWDebugFakeLocation destinationLocation];
    if (destinationLocation) {
        MKPointAnnotation *destinationAnnotation = [self getAnnotation:FWDebugDestinationSubtitle alreadyExist:NO];
        destinationAnnotation.coordinate = destinationLocation.coordinate;
        destinationAnnotation.title = [NSString stringWithFormat:@"%f,%f", destinationLocation.coordinate.latitude, destinationLocation.coordinate.longitude];
    } else {
        MKPointAnnotation *destinationAnnotation = [self getAnnotation:FWDebugDestinationSubtitle alreadyExist:YES];
        if (destinationAnnotation) {
            [self.mapView removeAnnotation:destinationAnnotation];
        }
    }
    
    MKPointAnnotation *touchAnnotation = [self getAnnotation:FWDebugTouchSubtitle alreadyExist:YES];
    if (touchAnnotation) {
        [self.mapView removeAnnotation:touchAnnotation];
    }
}

- (MKPointAnnotation *)getAnnotation:(NSString *)subtitle alreadyExist:(BOOL)alreadyExist
{
    MKPointAnnotation *annotation = nil;
    for (id<MKAnnotation> mapAnnotation in self.mapView.annotations) {
        if (mapAnnotation.subtitle && [mapAnnotation.subtitle isEqualToString:subtitle]) {
            annotation = (MKPointAnnotation *)mapAnnotation;
            break;
        }
    }
    
    if (!annotation && !alreadyExist) {
        annotation = [[MKPointAnnotation alloc] init];
        annotation.subtitle = subtitle;
        [self.mapView addAnnotation:annotation];
    }
    return annotation;
}

#pragma mark - Action

- (void)actionSwitch:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UISwitch *cellSwitch = (UISwitch *)cell.accessoryView;
    if (!cellSwitch.on) {
        [CLLocationManager fwDebugFakeLocation];
        
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:@"FWDebugFakeLocation"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self configSwitch:cell indexPath:indexPath];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"FWDebugFakeLocation"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self configSwitch:cell indexPath:indexPath];
    }
}

- (void)actionLabel:(NSIndexPath *)indexPath
{
    NSString *text = nil;
    if (indexPath.row == 0) {
        text = [FWDebugFakeLocation currentLocationString];
    } else if (indexPath.row == 1) {
        text = [FWDebugFakeLocation destinationLocationString];
    }
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    typeof(self) __weak weakSelf = self;
    [FWDebugFakeLocation showPrompt:self title:(indexPath.row > 1 ? @"Input Value" : @"Input Location") message:nil text:text block:^(BOOL confirm, NSString *text) {
        if (confirm) {
            if (indexPath.row == 0) {
                [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugFakeLocationCurrent"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [weakSelf configMap];
                
                CLLocation *currentLocation = [FWDebugFakeLocation currentLocation];
                if (currentLocation) {
                    [weakSelf.mapView setCenterCoordinate:currentLocation.coordinate];
                }
            } else if (indexPath.row == 1) {
                [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugFakeLocationDestination"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [weakSelf configMap];
                
                CLLocation *destinationLocation = [FWDebugFakeLocation destinationLocation];
                if (destinationLocation) {
                    [weakSelf.mapView setCenterCoordinate:destinationLocation.coordinate];
                }
            } else {
                [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"FWDebugFakeLocationTime"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            [weakSelf configLabel:cell indexPath:indexPath];
        }
    }];
}

- (void)actionMap:(UITapGestureRecognizer *)gesture
{
    CGPoint point = [gesture locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    MKPointAnnotation *annotation = [self getAnnotation:FWDebugTouchSubtitle alreadyExist:NO];
    annotation.coordinate = coordinate;
    annotation.title = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
    [UIPasteboard generalPasteboard].string = annotation.title ?: @"";
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    NSArray *annotationSubtitles = @[FWDebugTouchSubtitle, FWDebugCurrentSubtitle, FWDebugDestinationSubtitle];
    NSInteger annotationIndex = annotation.subtitle ? [annotationSubtitles indexOfObject:annotation.subtitle] : NSNotFound;
    if (annotationIndex == NSNotFound) {
        return nil;
    }
    
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"FakeAnnotationView"];
    if (!annotationView) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@"FakeAnnotationView"];
        annotationView.canShowCallout = YES;
    }
    
    annotationView.annotation = annotation;
    if (annotationIndex == 0) {
        if ([annotationView respondsToSelector:@selector(pinTintColor)]) {
            annotationView.pinTintColor = [MKPinAnnotationView purplePinColor];
        } else {
            annotationView.pinColor = MKPinAnnotationColorPurple;
        }
    } else if (annotationIndex == 1) {
        if ([annotationView respondsToSelector:@selector(pinTintColor)]) {
            annotationView.pinTintColor = [MKPinAnnotationView redPinColor];
        } else {
            annotationView.pinColor = MKPinAnnotationColorRed;
        }
    } else {
        if ([annotationView respondsToSelector:@selector(pinTintColor)]) {
            annotationView.pinTintColor = [MKPinAnnotationView greenPinColor];
        } else {
            annotationView.pinColor = MKPinAnnotationColorGreen;
        }
    }
    return annotationView;
}

@end
