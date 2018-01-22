//
//  FWDebugRuntimeBrowser.h
//  FWDebug
//
//  Created by wuyong on 17/2/22.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FWDebugRuntimeBrowser : UIViewController

- (instancetype)initWithClassName:(NSString *)className;

- (instancetype)initWithProtocolName:(NSString *)protocolName;

@end
