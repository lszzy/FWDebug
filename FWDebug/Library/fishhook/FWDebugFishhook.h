//
//  FWDebugFishhook.h
//  FWDebug
//
//  Created by wuyong on 17/3/5.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FWDebugFishhook : NSObject

+ (BOOL)isLogEnabled;

+ (void)logMessage:(NSString *)message;

+ (NSArray *)allLogMessages;

@end
