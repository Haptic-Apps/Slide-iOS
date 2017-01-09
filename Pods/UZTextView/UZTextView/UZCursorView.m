//
//  UZCursorView.m
//  UZTextView
//
//  Created by sonson on 2013/07/19.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZCursorView.h"

#define UZ_CURSOR_BALL_RADIUS			4
#define UZ_CURSOR_POLE_WIDTH			2
#define UZ_CURSOR_POLE_Y_MARGIN			7

#define UZ_CURSOR_HORIZONTAL_MARGIN1	30
#define UZ_CURSOR_HORIZONTAL_MARGIN2	10
#define UZ_CURSOR_VERTICAL_MARGIN		20

@implementation UZCursorView

+ (CGRect)cursorRectWithEdgeRect:(CGRect)rect cursorDirection:(UZTextViewCursorDirection)direction {
	if (direction == UZTextViewUpCursor) {
		return CGRectMake(rect.origin.x - UZ_CURSOR_HORIZONTAL_MARGIN1,
						  rect.origin.y - UZ_CURSOR_VERTICAL_MARGIN,
						  UZ_CURSOR_HORIZONTAL_MARGIN1 + UZ_CURSOR_HORIZONTAL_MARGIN2,
						  rect.size.height + UZ_CURSOR_VERTICAL_MARGIN * 2);
	}
	else {
		return CGRectMake(rect.origin.x - UZ_CURSOR_HORIZONTAL_MARGIN2,
						  rect.origin.y - UZ_CURSOR_VERTICAL_MARGIN,
						  UZ_CURSOR_HORIZONTAL_MARGIN1 + UZ_CURSOR_HORIZONTAL_MARGIN2,
						  rect.size.height + UZ_CURSOR_VERTICAL_MARGIN * 2);
	}
}

- (id)initWithCursorDirection:(UZTextViewCursorDirection)direction {
	self = [super initWithFrame:CGRectZero];
	_direction = direction;
	self.backgroundColor = [UIColor clearColor];
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGRect lineRect;
	CGPoint circleCenter;

#ifdef _UZTEXTVIEW_DEBUG_
	// for debug
	[[UIColor blueColor] setStroke];
	CGContextStrokeRect(context, CGRectInset(rect, 1, 1));
#endif
	
	if (_direction == UZTextViewUpCursor) {
		circleCenter = CGPointMake(UZ_CURSOR_HORIZONTAL_MARGIN1 - 1, UZ_CURSOR_VERTICAL_MARGIN - UZ_CURSOR_POLE_Y_MARGIN);
		lineRect = CGRectMake(
							  circleCenter.x - UZ_CURSOR_POLE_WIDTH/2, circleCenter.y,
							  UZ_CURSOR_POLE_WIDTH, rect.size.height - UZ_CURSOR_VERTICAL_MARGIN*2 + UZ_CURSOR_POLE_Y_MARGIN
							  );
	}
	else {
		circleCenter = CGPointMake(UZ_CURSOR_HORIZONTAL_MARGIN2, rect.size.height - (UZ_CURSOR_VERTICAL_MARGIN - UZ_CURSOR_POLE_Y_MARGIN));
		lineRect = CGRectMake(
							  circleCenter.x - UZ_CURSOR_POLE_WIDTH/2, circleCenter.y - (rect.size.height - UZ_CURSOR_VERTICAL_MARGIN*2 + UZ_CURSOR_POLE_Y_MARGIN),
							  UZ_CURSOR_POLE_WIDTH, rect.size.height - UZ_CURSOR_VERTICAL_MARGIN*2 + UZ_CURSOR_POLE_Y_MARGIN
							  );
	}
	CGContextAddArc(context, circleCenter.x, circleCenter.y, UZ_CURSOR_BALL_RADIUS, 0, 2 * M_PI, 0);
	CGContextClosePath(context);
	[[self.tintColor colorWithAlphaComponent:1] setFill];
	CGContextFillPath(context);
	CGContextFillRect(context, lineRect);
}

@end
