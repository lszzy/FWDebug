//
//  FLEXExplorerToolbar+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 17/2/27.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXExplorerToolbar.h"
#import "FLEXExplorerToolbarItem.h"

@class FWDebugFpsData;

@interface FLEXExplorerToolbar (FWDebug)

+ (void)fwDebugLoad;

- (FLEXExplorerToolbarItem *)fwDebugFpsItem;

@end

@interface FLEXExplorerToolbarItem (FWDebug)

@property (nonatomic, assign) BOOL fwDebugShowRuler;
@property (nonatomic, assign) BOOL fwDebugIsRuler;

- (void)setFpsData:(FWDebugFpsData *)fpsData;

@end
