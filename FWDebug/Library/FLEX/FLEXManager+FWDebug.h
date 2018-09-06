//
//  FLEXManager+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 17/2/28.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXManager.h"
#import "FWDebugFpsInfo.h"

@interface FLEXManager (FWDebug) <FWDebugFpsInfoDelegate>

+ (void)fwDebugLoad;

@end
