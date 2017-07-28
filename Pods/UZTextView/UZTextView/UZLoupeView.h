//
//  UZLoupeView.h
//  UZTextView
//
//  Created by sonson on 2013/07/10.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface UZLoupeView : UIView <CAAnimationDelegate> {
	CGFloat		_loupeRadius;
	UIImage		*_image;
}
- (id)initWithRadius:(CGFloat)radius;
- (void)setVisible:(BOOL)visible animated:(BOOL)animated;
- (void)updateAtLocation:(CGPoint)location textView:(UIView*)textView;
@property (nonatomic, copy) UIColor *textViewBackgroundColor;
@end
