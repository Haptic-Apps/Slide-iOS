//
//  BGTableViewRowActionWithImage.m
//  BGTableViewRowActionWithImage
//
//  Created by Ben Guild on 8/20/15.
//  Copyright (c) 2015 Ben Guild. All rights reserved.
//

#import "BGTableViewRowActionWithImage.h"


#define fontSize_iOS8AndUpDefault 18.0f
#define fontSize_actuallyUsedUnderImage 13.0f

#define margin_horizontal_iOS8AndUp 15.0f
#define margin_vertical_betweenTextAndImage (cellHeight>=64.0f ? 3.0f : 2.0f)

#define fittingMultiplier 0.40f
#define imagePaddingHorizontal 20.0

@implementation BGTableViewRowActionWithImage

#pragma mark - Derived constructors

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style
                             title:(NSString *)title
                   backgroundColor:(UIColor *)backgroundColor
                             image:(UIImage *)image
                     forCellHeight:(NSUInteger)cellHeight
                           handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler;
{
    return [self rowActionWithStyle:style title:title titleColor:[UIColor whiteColor] backgroundColor:backgroundColor image:image forCellHeight:cellHeight andFittedWidth:NO handler:handler];
}

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style
                             title:(NSString *)title
                        titleColor:(UIColor *)titleColor
                   backgroundColor:(UIColor *)backgroundColor
                             image:(UIImage *)image
                     forCellHeight:(NSUInteger)cellHeight
                           handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler
{
    return [self rowActionWithStyle:style title:title titleColor:titleColor backgroundColor:backgroundColor image:image forCellHeight:cellHeight andFittedWidth:NO handler:handler];
}

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style
                             title:(NSString *)title
                   backgroundColor:(UIColor *)backgroundColor
                             image:(UIImage *)image
                     forCellHeight:(NSUInteger)cellHeight
                    andFittedWidth:(BOOL)isWidthFitted
                           handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler
{
    return [self rowActionWithStyle:style title:title titleColor:[UIColor whiteColor] backgroundColor:backgroundColor image:image forCellHeight:cellHeight andFittedWidth:isWidthFitted handler:handler];
}

#pragma mark - Main constructor

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style title:(NSString *)title titleColor:(UIColor *)titleColor backgroundColor:(UIColor *)backgroundColor image:(UIImage *)image forCellHeight:(NSUInteger)cellHeight andFittedWidth:(BOOL)isWidthFitted handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler
{
    if (title==nil && image!=nil)
    {
        CGFloat emptySpaceWidth=[@"\u3000" boundingRectWithSize:CGSizeMake(MAXFLOAT, cellHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:fontSize_actuallyUsedUnderImage] } context:nil].size.width;
        
        CGFloat number=ceil((imagePaddingHorizontal+image.size.width+imagePaddingHorizontal)/emptySpaceWidth);
        title=[@"" stringByPaddingToLength:number withString:@"\u3000" startingAtIndex:0];
        
    }
    
    __block NSUInteger titleMaximumLineLength=0;
    
    [title enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop)
    {
        titleMaximumLineLength=MAX(titleMaximumLineLength, [line length]);
        
    } ];
    
    float titleMultiplier=(isWidthFitted ? fittingMultiplier : (fontSize_actuallyUsedUnderImage/fontSize_iOS8AndUpDefault)/1.1f); // NOTE: This isn't exact, but it's close enough in most instances? I tested with full-width Asian characters and it accounts for those pretty well.
    
    NSString *titleSpaceString=[@"" stringByPaddingToLength:titleMaximumLineLength*titleMultiplier withString:@"\u3000" startingAtIndex:0];
    
    BGTableViewRowActionWithImage *rowAction=(BGTableViewRowActionWithImage *)[self rowActionWithStyle:style title:titleSpaceString handler:handler];
    
    CGFloat contentWidth=[titleSpaceString boundingRectWithSize:CGSizeMake(MAXFLOAT, cellHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:fontSize_iOS8AndUpDefault] } context:nil].size.width;
    
    CGSize frameGuess=CGSizeMake((margin_horizontal_iOS8AndUp*2)+contentWidth, cellHeight);
    
    CGSize tripleFrame=CGSizeMake(frameGuess.width*3.0f, frameGuess.height*3.0f);
    
    UIGraphicsBeginImageContextWithOptions(tripleFrame, YES, [[UIScreen mainScreen] scale]);
    CGContextRef context=UIGraphicsGetCurrentContext();
    
    [backgroundColor set];
    CGContextFillRect(context, CGRectMake(0, 0, tripleFrame.width, tripleFrame.height));
    
    CGSize drawnTextSize=[title boundingRectWithSize:CGSizeMake(MAXFLOAT, cellHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:fontSize_actuallyUsedUnderImage] } context:nil].size;
    
    CGFloat imageInsetVertical = [image size].height/2.0;
    if ([title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0) {
        imageInsetVertical=[image size].height-(margin_vertical_betweenTextAndImage/2.0f)+2.0f;
    }
    
    [image drawAtPoint:CGPointMake((frameGuess.width/2.0f)-([image size].width/2.0f), (frameGuess.height/2.0f)-imageInsetVertical)];
    [title drawInRect:CGRectMake(((frameGuess.width/2.0f)-(drawnTextSize.width/2.0f))*([[UIApplication sharedApplication] userInterfaceLayoutDirection]==UIUserInterfaceLayoutDirectionRightToLeft ? -1 : 1), (frameGuess.height/2.0f)+(margin_vertical_betweenTextAndImage/2.0f)+2.0f, frameGuess.width, frameGuess.height) withAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:fontSize_actuallyUsedUnderImage], NSForegroundColorAttributeName: titleColor }];
    
    [rowAction setBackgroundColor:[UIColor colorWithPatternImage:UIGraphicsGetImageFromCurrentImageContext()]];
    UIGraphicsEndImageContext();
    ////
    
    return rowAction;
    
}

@end
