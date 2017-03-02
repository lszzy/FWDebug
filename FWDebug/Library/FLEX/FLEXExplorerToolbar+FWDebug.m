//
//  FLEXExplorerToolbar+FWDebug.m
//  FWDebug
//
//  Created by wuyong on 17/2/27.
//  Copyright © 2017年 ocphp.com. All rights reserved.
//

#import "FLEXExplorerToolbar+FWDebug.h"
#import "FLEXUtility.h"
#import "FWDebugFpsInfo.h"
#import <objc/runtime.h>

@implementation FLEXExplorerToolbar (FWDebug)

+ (void)load
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    method_exchangeImplementations(
                                   class_getInstanceMethod(self, @selector(setToolbarItems:)),
                                   class_getInstanceMethod(self, @selector(fwDebugSetToolbarItems:))
                                   );
#pragma clang diagnostic pop
}

- (FLEXToolbarItem *)fwDebugFpsItem
{
    FLEXToolbarItem *item = objc_getAssociatedObject(self, _cmd);
    if (!item) {
        item = [FLEXToolbarItem toolbarItemWithTitle:@"" image:nil];
        objc_setAssociatedObject(self, _cmd, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return item;
}

- (void)fwDebugSetToolbarItems:(NSArray *)toolbarItems
{
    NSMutableArray *debugItems = [NSMutableArray arrayWithArray:toolbarItems];
    [self addSubview:self.fwDebugFpsItem];
    [debugItems insertObject:self.fwDebugFpsItem atIndex:debugItems.count > 2 ? 2 : 0];
    [self fwDebugSetToolbarItems:debugItems];
}

@end

@interface FLEXToolbarItem ()

@property (nonatomic, copy) NSAttributedString *attributedTitle;
@property (nonatomic, strong) UIImage *image;

@end

@implementation FLEXToolbarItem (FWDebug)

- (void)setFpsData:(FWDebugFpsData *)fpsData
{
    // memory
    NSString *memoryStr = [NSString stringWithFormat:@"%.0fMB", fpsData.memory];
    NSDictionary *memoryAttr = @{
                                 NSFontAttributeName: [FLEXUtility defaultFontOfSize:10.0],
                                 NSForegroundColorAttributeName: [self colorForFpsState:fpsData.memoryState],
                                 };
    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:memoryStr attributes:memoryAttr];
    self.attributedTitle = attrTitle;
    [self setAttributedTitle:attrTitle forState:UIControlStateNormal];
    
    // image
    UIImage *fpsImage = [self imageForFpsData:fpsData];
    self.image = fpsImage;
    [self setImage:fpsImage forState:UIControlStateNormal];
}

- (UIColor *)colorForFpsState:(NSInteger)fpsState
{
    if (fpsState > 0) {
        return [UIColor blackColor];
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
                              NSFontAttributeName: [FLEXUtility defaultFontOfSize:12.0],
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
    [[UIColor colorWithWhite:121.0/255.0 alpha:0.75] setStroke];
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

@end
