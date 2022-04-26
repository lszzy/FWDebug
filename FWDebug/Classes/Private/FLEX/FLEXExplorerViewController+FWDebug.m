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

@interface FWDebugViewOverlay : UIView

@property (nonatomic, strong) UIView *viewOverlay;

@property (nonatomic, assign) UIEdgeInsets distanceInsets;
@property (nonatomic, assign) CGRect previousRect;
@property (nonatomic, assign) CGRect selectedRect;
@property (nonatomic, assign) BOOL showingOverlay;

@end

@implementation FWDebugViewOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _viewOverlay = [UIView new];
        _viewOverlay.layer.borderWidth = 1.0;
        [self addSubview:_viewOverlay];
    }
    return self;
}

- (void)showOverlay:(UIView *)superView previousView:(UIView *)previousView selectedView:(UIView *)selectedView {
    self.previousRect = [superView convertRect:previousView.bounds fromView:previousView];
    self.selectedRect = [superView convertRect:selectedView.bounds fromView:selectedView];
    if (CGRectEqualToRect(self.selectedRect, self.previousRect)) {
        self.distanceInsets = UIEdgeInsetsZero;
    } else if (CGRectContainsRect(self.selectedRect, self.previousRect) ||
               CGRectContainsRect(self.previousRect, self.selectedRect)) {
        self.distanceInsets = UIEdgeInsetsMake(fabs(CGRectGetMinY(self.selectedRect) - CGRectGetMinY(self.previousRect)), fabs(CGRectGetMinX(self.selectedRect) - CGRectGetMinX(self.previousRect)), fabs(CGRectGetMaxY(self.selectedRect) - CGRectGetMaxY(self.previousRect)), fabs(CGRectGetMaxX(self.selectedRect) - CGRectGetMaxX(self.previousRect)));
    } else {
        self.distanceInsets = UIEdgeInsetsMake(CGRectGetMinY(self.previousRect) - CGRectGetMaxY(self.selectedRect), CGRectGetMinX(self.previousRect) - CGRectGetMaxX(self.selectedRect), CGRectGetMinY(self.selectedRect) - CGRectGetMaxY(self.previousRect), CGRectGetMinX(self.selectedRect) - CGRectGetMaxX(self.previousRect));
    }
    
    UIColor *overlayColor = [FLEXUtility consistentRandomColorForObject:previousView];
    self.viewOverlay.backgroundColor = [overlayColor colorWithAlphaComponent:0.2];
    self.viewOverlay.layer.borderColor = overlayColor.CGColor;
    self.viewOverlay.frame = self.previousRect;
    
    self.showingOverlay = YES;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (!self.showingOverlay) return;
    if (CGRectEqualToRect(self.previousRect, self.selectedRect)) return;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (CGRectContainsRect(self.selectedRect, self.previousRect) || CGRectContainsRect(self.previousRect, self.selectedRect)) {
        CGRect superRect = CGRectContainsRect(self.selectedRect, self.previousRect) ? self.selectedRect : self.previousRect;
        CGRect subRect = CGRectContainsRect(self.selectedRect, self.previousRect) ? self.previousRect : self.selectedRect;
        
        CGPoint startPoint = CGPointMake(CGRectGetMidX(subRect), CGRectGetMinY(subRect));
        CGPoint endPoint = CGPointMake(CGRectGetMidX(subRect), CGRectGetMinY(superRect));
        [self drawOverlay:context rectEdge:UIRectEdgeTop edgeInsets:self.distanceInsets startPoint:startPoint endPoint:endPoint];
        
        startPoint = CGPointMake(CGRectGetMidX(subRect), CGRectGetMaxY(subRect));
        endPoint = CGPointMake(CGRectGetMidX(subRect), CGRectGetMaxY(superRect));
        [self drawOverlay:context rectEdge:UIRectEdgeBottom edgeInsets:self.distanceInsets startPoint:startPoint endPoint:endPoint];
        
        startPoint = CGPointMake(CGRectGetMinX(subRect), CGRectGetMidY(subRect));
        endPoint = CGPointMake(CGRectGetMinX(superRect), CGRectGetMidY(subRect));
        [self drawOverlay:context rectEdge:UIRectEdgeLeft edgeInsets:self.distanceInsets startPoint:startPoint endPoint:endPoint];
        
        startPoint = CGPointMake(CGRectGetMaxX(subRect), CGRectGetMidY(subRect));
        endPoint = CGPointMake(CGRectGetMaxX(superRect), CGRectGetMidY(subRect));
        [self drawOverlay:context rectEdge:UIRectEdgeRight edgeInsets:self.distanceInsets startPoint:startPoint endPoint:endPoint];
    } else {
        if (self.distanceInsets.top > 0) {
            CGPoint startPoint = CGPointMake(CGRectGetMidX(self.previousRect), CGRectGetMinY(self.previousRect));
            CGPoint endPoint = CGPointMake(CGRectGetMidX(self.previousRect), CGRectGetMaxY(self.selectedRect));
            [self drawOverlay:context rectEdge:UIRectEdgeTop edgeInsets:self.distanceInsets startPoint:startPoint endPoint:endPoint];
        }
        
        if (self.distanceInsets.bottom > 0) {
            CGPoint startPoint = CGPointMake(CGRectGetMidX(self.previousRect), CGRectGetMaxY(self.previousRect));
            CGPoint endPoint = CGPointMake(CGRectGetMidX(self.previousRect), CGRectGetMinY(self.selectedRect));
            [self drawOverlay:context rectEdge:UIRectEdgeBottom edgeInsets:self.distanceInsets startPoint:startPoint endPoint:endPoint];
        }
        
        if (self.distanceInsets.left > 0) {
            CGPoint startPoint = CGPointMake(CGRectGetMinX(self.previousRect), CGRectGetMidY(self.previousRect));
            CGPoint endPoint = CGPointMake(CGRectGetMaxX(self.selectedRect), CGRectGetMidY(self.previousRect));
            [self drawOverlay:context rectEdge:UIRectEdgeLeft edgeInsets:self.distanceInsets startPoint:startPoint endPoint:endPoint];
        }
        
        if (self.distanceInsets.right > 0) {
            CGPoint startPoint = CGPointMake(CGRectGetMaxX(self.previousRect), CGRectGetMidY(self.previousRect));
            CGPoint endPoint = CGPointMake(CGRectGetMinX(self.selectedRect), CGRectGetMidY(self.previousRect));
            [self drawOverlay:context rectEdge:UIRectEdgeRight edgeInsets:self.distanceInsets startPoint:startPoint endPoint:endPoint];
        }
    }
}

- (void)drawOverlay:(CGContextRef)context
           rectEdge:(UIRectEdge)rectEdge
         edgeInsets:(UIEdgeInsets)edgeInsets
         startPoint:(CGPoint)startPoint
           endPoint:(CGPoint)endPoint {
    CGFloat lineWidth = 1;
    CGFloat rulerWidth = 8;
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetStrokeColorWithColor(context, UIColor.redColor.CGColor);
    NSString *drawString = nil;
    CGFloat drawSpacing = 4;
    CGSize drawSize = CGSizeZero;
    CGFloat lineHeight = [UIFont systemFontOfSize:12].lineHeight;
    NSDictionary *drawAttrs = @{NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: UIColor.redColor};
    
    switch (rectEdge) {
        case UIRectEdgeTop: {
            CGContextMoveToPoint(context, startPoint.x - rulerWidth / 2.0, startPoint.y - lineWidth / 2.0);
            CGContextAddLineToPoint(context, startPoint.x + rulerWidth / 2.0, startPoint.y - lineWidth / 2.0);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, startPoint.x, startPoint.y);
            CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, endPoint.x - rulerWidth / 2.0, endPoint.y + lineWidth / 2.0);
            CGContextAddLineToPoint(context, endPoint.x + rulerWidth / 2.0, endPoint.y + lineWidth / 2.0);
            CGContextStrokePath(context);
            
            drawString = [NSString stringWithFormat:@"%g", edgeInsets.top];
            [drawString drawAtPoint:CGPointMake(startPoint.x + drawSpacing, endPoint.y + edgeInsets.top / 2.0 - lineHeight / 2.0) withAttributes:drawAttrs];
            break;
        }
        case UIRectEdgeBottom: {
            CGContextMoveToPoint(context, startPoint.x - rulerWidth / 2.0, startPoint.y + lineWidth / 2.0);
            CGContextAddLineToPoint(context, startPoint.x + rulerWidth / 2.0, startPoint.y + lineWidth / 2.0);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, startPoint.x, startPoint.y);
            CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, endPoint.x - rulerWidth / 2.0, endPoint.y - lineWidth / 2.0);
            CGContextAddLineToPoint(context, endPoint.x + rulerWidth / 2.0, endPoint.y - lineWidth / 2.0);
            CGContextStrokePath(context);
            
            drawString = [NSString stringWithFormat:@"%g", edgeInsets.bottom];
            [drawString drawAtPoint:CGPointMake(startPoint.x + drawSpacing, startPoint.y + edgeInsets.bottom / 2.0 - lineHeight / 2.0) withAttributes:drawAttrs];
            break;
        }
        case UIRectEdgeLeft: {
            CGContextMoveToPoint(context, startPoint.x - lineWidth / 2.0, startPoint.y - rulerWidth / 2.0);
            CGContextAddLineToPoint(context, startPoint.x - lineWidth / 2.0, startPoint.y + rulerWidth / 2.0);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, startPoint.x, startPoint.y);
            CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, endPoint.x + lineWidth / 2.0, endPoint.y - rulerWidth / 2.0);
            CGContextAddLineToPoint(context, endPoint.x + lineWidth / 2.0, endPoint.y + rulerWidth / 2.0);
            CGContextStrokePath(context);
            
            drawString = [NSString stringWithFormat:@"%g", edgeInsets.left];
            drawSize = [drawString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:drawAttrs context:nil].size;
            [drawString drawAtPoint:CGPointMake(endPoint.x + edgeInsets.left / 2.0 - drawSize.width / 2.0, startPoint.y - drawSpacing - drawSize.height) withAttributes:drawAttrs];
            break;
        }
        case UIRectEdgeRight: {
            CGContextMoveToPoint(context, startPoint.x + lineWidth / 2.0, startPoint.y - rulerWidth / 2.0);
            CGContextAddLineToPoint(context, startPoint.x + lineWidth / 2.0, startPoint.y + rulerWidth / 2.0);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, startPoint.x, startPoint.y);
            CGContextAddLineToPoint(context, endPoint.x, endPoint.y);
            CGContextStrokePath(context);
            
            CGContextMoveToPoint(context, endPoint.x - lineWidth / 2.0, endPoint.y - rulerWidth / 2.0);
            CGContextAddLineToPoint(context, endPoint.x - lineWidth / 2.0, endPoint.y + rulerWidth / 2.0);
            CGContextStrokePath(context);
            
            drawString = [NSString stringWithFormat:@"%g", edgeInsets.right];
            drawSize = [drawString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin attributes:drawAttrs context:nil].size;
            [drawString drawAtPoint:CGPointMake(startPoint.x + edgeInsets.right / 2.0 - drawSize.width / 2.0, startPoint.y - drawSpacing - drawSize.height) withAttributes:drawAttrs];
            break;
        }
        default:
            break;
    }
}

@end

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
    
    FWDebugViewOverlay *viewOverlay = [self fwDebugViewOverlay:YES];
    viewOverlay.frame = self.view.bounds;
    [self.view addSubview:viewOverlay];
    [self.view bringSubviewToFront:viewOverlay];
    
    [viewOverlay showOverlay:self.view previousView:previousView selectedView:selectedView];
    UIEdgeInsets distanceInsets = viewOverlay.distanceInsets;
    self.explorerToolbar.selectedViewDescription = [NSString stringWithFormat:@"Distance: {%g, %g, %g, %g}", distanceInsets.top, distanceInsets.left, distanceInsets.bottom, distanceInsets.right];
    self.explorerToolbar.selectedViewOverlayColor = [FLEXUtility consistentRandomColorForObject:previousView];
}

- (BOOL)fwDebugRemoveOverlay {
    FWDebugViewOverlay *viewOverlay = [self fwDebugViewOverlay:NO];
    if (viewOverlay && viewOverlay.superview) {
        [viewOverlay removeFromSuperview];
        return YES;
    }
    return NO;
}

- (FWDebugViewOverlay *)fwDebugViewOverlay:(BOOL)lazyload {
    FWDebugViewOverlay *viewOverlay = objc_getAssociatedObject(self, _cmd);
    if (!viewOverlay && lazyload) {
        viewOverlay = [FWDebugViewOverlay new];
        objc_setAssociatedObject(self, _cmd, viewOverlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return viewOverlay;
}

@end
