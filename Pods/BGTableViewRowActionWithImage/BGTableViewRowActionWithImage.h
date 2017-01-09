//
//  BGTableViewRowActionWithImage.h
//  BGTableViewRowActionWithImage
//
//  Created by Ben Guild on 8/20/15.
//  Copyright (c) 2015 Ben Guild. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BGTableViewRowActionWithImage : UITableViewRowAction

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style title:(NSString *)title backgroundColor:(UIColor *)backgroundColor image:(UIImage *)image forCellHeight:(NSUInteger)cellHeight handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler;

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style title:(NSString *)title titleColor:(UIColor *)titleColor backgroundColor:(UIColor *)backgroundColor image:(UIImage *)image forCellHeight:(NSUInteger)cellHeight handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler;

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style title:(NSString *)title backgroundColor:(UIColor *)backgroundColor image:(UIImage *)image forCellHeight:(NSUInteger)cellHeight andFittedWidth:(BOOL)isWidthFitted handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler;

+ (instancetype)rowActionWithStyle:(UITableViewRowActionStyle)style title:(NSString *)title titleColor:(UIColor *)titleColor backgroundColor:(UIColor *)backgroundColor image:(UIImage *)image forCellHeight:(NSUInteger)cellHeight andFittedWidth:(BOOL)isWidthFitted handler:(void (^)(UITableViewRowAction *, NSIndexPath *))handler;


@end
