//
//  FLEXFileBrowserController+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 17/2/24.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXFileBrowserController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXFileBrowserController (FWDebug)

+ (void)fwDebugLoad;

@end

@interface UINavigationController (FWDebug)

@property (nonatomic, copy, nullable) BOOL (^fwDebugFileHandler)(FLEXFileBrowserController *fileBrowser, NSString *filePath);

@end

NS_ASSUME_NONNULL_END
