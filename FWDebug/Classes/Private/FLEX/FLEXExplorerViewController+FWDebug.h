//
//  FLEXExplorerViewController+FWDebug.h
//  FWDebug
//
//  Created by wuyong on 2022/4/25.
//

#import "FLEXExplorerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface FLEXExplorerViewController (FWDebug)

+ (void)fwDebugLoad;

- (BOOL)fwDebugRemoveOverlay;

@end

NS_ASSUME_NONNULL_END
