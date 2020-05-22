//
//  FWDebugGCDWebServer.h
//  FWDebug
//
//  Created by wuyong on 17/2/22.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXTableViewController.h"

/*!
 @discussion 原始：NSString* bundlePath = [[NSBundle bundleForClass:[GCDWebUploader class]] pathForResource:@"GCDWebUploader" ofType:@"bundle"]; 修改：NSString* bundlePath = [[NSBundle bundleWithPath:[FWDebugWebBundle fwDebugBundlePath]] pathForResource:@"GCDWebUploader" ofType:@"bundle"];
 */
@interface FWDebugWebServer : FLEXTableViewController

@end
