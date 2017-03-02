//
//  FWDebugWebUploader.h
//  FWDebug
//
//  Created by wuyong on 16/6/23.
//  Copyright © 2016年 ocphp. All rights reserved.
//

#import "GCDWebServer.h"

@interface FWDebugWebUploader : GCDWebServer

@property(nonatomic, readonly) NSString *uploadDirectory;

- (instancetype)initWithUploadDirectory:(NSString*)path;

@end
