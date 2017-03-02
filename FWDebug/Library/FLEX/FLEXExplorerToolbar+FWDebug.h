//
//  FLEXExplorerToolbar+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 17/2/27.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FLEXExplorerToolbar.h"
#import "FLEXToolbarItem.h"

@class FWDebugFpsData;

@interface FLEXExplorerToolbar (FWDebug)

- (FLEXToolbarItem *)fwDebugFpsItem;

@end

@interface FLEXToolbarItem (FWDebug)

- (void)setFpsData:(FWDebugFpsData *)fpsData;

@end
