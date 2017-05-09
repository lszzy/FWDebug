//
//  JPEngine+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 17/3/9.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "JPEngine.h"

@interface JPEngine (FWDebug)

+ (void)fwDebugLoad;

+ (NSString *)fwDebugScriptPath;

+ (NSString *)fwDebugBundlePath;

@end
