//
//  FLEXExplorerViewController+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 2022/4/25.
//

#import "FLEXExplorerViewController+FWDebug.h"
#import "FLEXExplorerToolbar+FWDebug.h"
#import "FWDebugManager+FWDebug.h"
#import "FLEXGlobalsViewController.h"
#import "FLEXUtility.h"
#import <objc/runtime.h>

@interface FLEXExplorerViewController ()

@property (nonatomic) NSUInteger currentMode;
@property (nonatomic) UIView *selectedView;

@end

@implementation FLEXExplorerViewController (FWDebug)

+ (void)fwDebugLoad {
    [FWDebugManager swizzleMethod:@selector(viewDidLoad) in:[FLEXGlobalsViewController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^(__unsafe_unretained FLEXGlobalsViewController *selfObject) {
            ((void (*)(id, SEL))originalIMP())(selfObject, originalCMD);
            selfObject.title = @"💪  FLEX - FWDebug";
        };
    }];
    
    [FWDebugManager swizzleMethod:@selector(setCurrentMode:) in:[FLEXExplorerViewController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^(__unsafe_unretained FLEXExplorerViewController *selfObject, NSUInteger currentMode) {
            ((void (*)(id, SEL, NSUInteger))originalIMP())(selfObject, originalCMD, currentMode);
            selfObject.explorerToolbar.selectItem.fwDebugIsRuler = NO;
            selfObject.explorerToolbar.fwDebugFpsItem.fwDebugShowRuler = currentMode == 1;
            [selfObject fwDebugRemoveOverlay];
        };
    }];
    
    [FWDebugManager swizzleMethod:@selector(setSelectedView:) in:[FLEXExplorerViewController class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^(__unsafe_unretained FLEXExplorerViewController *selfObject, UIView *selectedView) {
            BOOL isRuler = selfObject.explorerToolbar.selectItem.fwDebugIsRuler;
            UIView *previousView = isRuler ? selfObject.selectedView : nil;
            ((void (*)(id, SEL, UIView *))originalIMP())(selfObject, originalCMD, selectedView);
            if (isRuler) [selfObject fwDebugShowOverlay:previousView selectedView:selectedView];
        };
    }];
}

- (void)fwDebugShowOverlay:(UIView *)previousView selectedView:(UIView *)selectedView {
    if ([self fwDebugRemoveOverlay]) return;
    if (!previousView || !selectedView || [previousView isEqual:selectedView]) return;
    
    CGRect previousRect = [self.view convertRect:previousView.bounds fromView:previousView];
    CGRect selectedRect = [self.view convertRect:selectedView.bounds fromView:selectedView];
    UIEdgeInsets distanceInsets;
    if (CGRectContainsRect(selectedRect, previousRect) || CGRectContainsRect(previousRect, selectedRect)) {
        distanceInsets = UIEdgeInsetsMake(
            fabs(CGRectGetMinY(selectedRect) - CGRectGetMinY(previousRect)),
            fabs(CGRectGetMinX(selectedRect) - CGRectGetMinX(previousRect)),
            fabs(CGRectGetMaxY(selectedRect) - CGRectGetMaxY(previousRect)),
            fabs(CGRectGetMaxX(selectedRect) - CGRectGetMaxX(previousRect))
        );
    } else {
        distanceInsets = UIEdgeInsetsMake(
            fabs(CGRectGetMinY(previousRect) - CGRectGetMaxY(selectedRect)),
            fabs(CGRectGetMinX(previousRect) - CGRectGetMaxX(selectedRect)),
            fabs(CGRectGetMaxY(previousRect) - CGRectGetMinY(selectedRect)),
            fabs(CGRectGetMaxX(previousRect) - CGRectGetMinX(selectedRect))
        );
    }
    
    self.explorerToolbar.selectedViewDescription = [NSString stringWithFormat:@"Distance: {%g, %g, %g, %g}", distanceInsets.top, distanceInsets.left, distanceInsets.bottom, distanceInsets.right];
    self.explorerToolbar.selectedViewOverlayColor = [FLEXUtility consistentRandomColorForObject:previousView];
    
    UIView *viewOverlay = [self fwDebugViewOverlay:YES];
    UIColor *outlineColor = [FLEXUtility consistentRandomColorForObject:previousView];
    viewOverlay.backgroundColor = [outlineColor colorWithAlphaComponent:0.2];
    viewOverlay.layer.borderColor = outlineColor.CGColor;
    viewOverlay.frame = previousRect;
    [self.view addSubview:viewOverlay];
    [self.view bringSubviewToFront:viewOverlay];
}

- (BOOL)fwDebugRemoveOverlay {
    UIView *viewOverlay = [self fwDebugViewOverlay:NO];
    if (viewOverlay && viewOverlay.superview) {
        [viewOverlay removeFromSuperview];
        return YES;
    }
    return NO;
}

- (UIView *)fwDebugViewOverlay:(BOOL)lazyload {
    UIView *viewOverlay = objc_getAssociatedObject(self, _cmd);
    if (!viewOverlay && lazyload) {
        viewOverlay = [UIView new];
        viewOverlay.layer.borderWidth = 1.0;
        objc_setAssociatedObject(self, _cmd, viewOverlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return viewOverlay;
}

@end
