//
//  FWDebugWebBundle.h
//  FWDebug
//
//  Created by wuyong on 16/6/23.
//  Copyright © 2016年 ocphp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FWDebugWebBundle : NSObject

@property (nonatomic, strong, readonly) NSString *bundlePath;

+ (instancetype)sharedInstance;

- (void)createBundle;

- (void)deleteBundle;

@end
