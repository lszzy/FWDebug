//
//  FLEXExplorerToolbar+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/27.
//  Copyright © 2017年 wuyong.site. All rights reserved.
//

#import "FLEXExplorerToolbar+FWDebug.h"
#import "FLEXColor.h"
#import "FLEXResources.h"
#import "FWDebugFpsInfo.h"
#import "FWDebugManager+FWDebug.h"
#import "FLEXManager+FWDebug.h"
#import <objc/runtime.h>

@interface FLEXExplorerToolbarItem ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic) UIImage *image;

@end

@implementation FLEXExplorerToolbarItem (FWDebug)

- (BOOL)fwDebugShowRuler
{
    return [objc_getAssociatedObject(self, @selector(fwDebugShowRuler)) boolValue];
}

- (void)setFwDebugShowRuler:(BOOL)showRuler
{
    objc_setAssociatedObject(self, @selector(fwDebugShowRuler), @(showRuler), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (showRuler) {
        self.title = @"ruler";
        self.image = [self rulerImage];
        [self setAttributedTitle:nil forState:UIControlStateNormal];
        [self setTitle:self.title forState:UIControlStateNormal];
        [self setImage:self.image forState:UIControlStateNormal];
    } else {
        [self setFpsData:FLEXManager.sharedManager.fwDebugFpsData];
    }
}

- (BOOL)fwDebugIsRuler
{
    return [objc_getAssociatedObject(self, @selector(fwDebugIsRuler)) boolValue];
}

- (void)setFwDebugIsRuler:(BOOL)isRuler
{
    objc_setAssociatedObject(self, @selector(fwDebugIsRuler), @(isRuler), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.title = isRuler ? @"ruler" : @"select";
    self.image = isRuler ? [self rulerImage] : FLEXResources.selectIcon;
    [self setTitle:self.title forState:UIControlStateNormal];
    [self setImage:self.image forState:UIControlStateNormal];
}

- (void)setFpsData:(FWDebugFpsData *)fpsData
{
    if (self.fwDebugShowRuler) return;
    
    // memory
    NSString *memoryStr = [NSString stringWithFormat:@"%.0fMB", fpsData.memory];
    NSDictionary *memoryAttr = @{
                                 NSFontAttributeName: [UIFont systemFontOfSize:10.0],
                                 NSForegroundColorAttributeName: [self colorForFpsState:fpsData.memoryState],
                                 };
    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:memoryStr attributes:memoryAttr];
    self.title = memoryStr;
    [self setAttributedTitle:attrTitle forState:UIControlStateNormal];
    
    // image
    UIImage *fpsImage = [self imageForFpsData:fpsData];
    self.image = fpsImage;
    [self setImage:fpsImage forState:UIControlStateNormal];
}

- (UIColor *)colorForFpsState:(NSInteger)fpsState
{
    if (fpsState > 0) {
        return FLEXColor.primaryTextColor;
    } else if (fpsState == 0) {
        return [UIColor orangeColor];
    } else {
        return [UIColor redColor];
    }
}

- (UIImage *)imageForFpsData:(FWDebugFpsData *)fpsData
{
    CGSize size = CGSizeMake(21.0, 21.0);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return nil;
    
    // fps
    NSString *fpsStr = @"-";
    UIColor *fpsColor = [self colorForFpsState:1];
    if (fpsData.fps > 0) {
        fpsStr = [NSString stringWithFormat:@"%.0f", fpsData.fps];
        fpsColor = [self colorForFpsState:fpsData.fpsState];
    }
    NSDictionary *fpsAttr = @{
                              NSFontAttributeName: [UIFont systemFontOfSize:12.0],
                              NSForegroundColorAttributeName: fpsColor,
                              };
    CGSize fpsSize = [fpsStr boundingRectWithSize:size
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:fpsAttr
                                          context:nil].size;
    [fpsStr drawAtPoint:CGPointMake(size.width / 2.0 - fpsSize.width / 2.0, size.height / 2.0 - fpsSize.height / 2.0)
         withAttributes:fpsAttr];
    
    // cpu
    CGFloat lineWidth = 2.0;
    UIBezierPath *totalPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(size.width / 2.0, size.height / 2.0)
                                                             radius:(size.width / 2.0 - lineWidth / 2.0)
                                                         startAngle:((M_PI * -90) / 180.f)
                                                           endAngle:((M_PI * 270) / 180.f)
                                                          clockwise:YES];
    CGContextSetLineWidth(context, lineWidth);
    [[UIColor colorWithWhite:121.0/255.0 alpha:0.5] setStroke];
    CGContextAddPath(context, totalPath.CGPath);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGFloat cpuAngle = -90 + (fpsData.cpu / 100.0) * 360;
    UIBezierPath *ratePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(size.width / 2.0, size.height / 2.0)
                                                            radius:(size.width / 2.0 - lineWidth / 2.0)
                                                        startAngle:((M_PI * -90) / 180.f)
                                                          endAngle:((M_PI * cpuAngle) / 180.f)
                                                         clockwise:YES];
    CGContextSetLineWidth(context, lineWidth);
    [[self colorForFpsState:fpsData.cpuState] setStroke];
    CGContextAddPath(context, ratePath.CGPath);
    CGContextDrawPath(context, kCGPathStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)rulerImage
{
    CGSize size = CGSizeMake(21.0, 21.0);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return nil;
    
    CGFloat lineWidth = 1.5;
    CGFloat rulerWidth = 6;
    UIBezierPath *totalPath = [UIBezierPath bezierPath];
    [totalPath moveToPoint:CGPointMake(lineWidth / 2.0, size.height / 2.0)];
    [totalPath addLineToPoint:CGPointMake(size.width - lineWidth, size.height / 2.0)];
    [totalPath moveToPoint:CGPointMake(lineWidth / 2.0, size.height / 2.0 - rulerWidth / 2.0)];
    [totalPath addLineToPoint:CGPointMake(lineWidth / 2.0, size.height / 2.0 + rulerWidth / 2.0)];
    [totalPath moveToPoint:CGPointMake(size.width - lineWidth, size.height / 2.0 - rulerWidth / 2.0)];
    [totalPath addLineToPoint:CGPointMake(size.width - lineWidth, size.height / 2.0 + rulerWidth / 2.0)];
    CGContextSetLineWidth(context, lineWidth);
    [FLEXColor.primaryTextColor setStroke];
    CGContextAddPath(context, totalPath.CGPath);
    CGContextDrawPath(context, kCGPathStroke);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@implementation FLEXExplorerToolbar (FWDebug)

+ (void)fwDebugLoad
{
    [FWDebugManager swizzleMethod:@selector(toolbarItems) in:[FLEXExplorerToolbar class] withBlock:^id(__unsafe_unretained Class targetClass, SEL originalCMD, IMP (^originalIMP)(void)) {
        return ^(__unsafe_unretained FLEXExplorerToolbar *selfObject) {
            NSArray *originItems = ((NSArray *(*)(id, SEL))originalIMP())(selfObject, originalCMD);
            
            NSMutableArray *debugItems = [originItems mutableCopy];
            [debugItems insertObject:selfObject.fwDebugFpsItem atIndex:debugItems.count > 2 ? 2 : 0];
            return [debugItems copy];
        };
    }];
}

- (FLEXExplorerToolbarItem *)fwDebugFpsItem
{
    FLEXExplorerToolbarItem *item = objc_getAssociatedObject(self, _cmd);
    if (!item) {
        item = [FLEXExplorerToolbarItem buttonWithType:UIButtonTypeCustom];
        item.title = @"";
        item.image = [UIImage new];
        item.tintColor = FLEXColor.iconColor;
        item.backgroundColor = UIColor.clearColor;
        item.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [item setTitle:item.title forState:UIControlStateNormal];
        [item setImage:item.image forState:UIControlStateNormal];
        [item setTitleColor:FLEXColor.primaryTextColor forState:UIControlStateNormal];
        [item setTitleColor:FLEXColor.deemphasizedTextColor forState:UIControlStateDisabled];
        [self addSubview:item];
        objc_setAssociatedObject(self, _cmd, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

@end
