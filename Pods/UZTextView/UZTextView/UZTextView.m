//
//  UZTextView.m
//  Text
//
//  Created by sonson on 2013/06/13.
//  Copyright (c) 2013年 sonson. All rights reserved.
//

#import "UZTextView.h"

#import "UZLoupeView.h"
#import "UZCursorView.h"

/**
 * To be written
 */
@implementation UIGestureRecognizer (UZTextView)

/**
 * To be written
 * \return To be written
 */
- (NSString*)stateDescription {
	if (self.state == UIGestureRecognizerStatePossible)
		return @"UIGestureRecognizerStatePossible";
	if (self.state == UIGestureRecognizerStateBegan)
		return @"UIGestureRecognizerStateBegan";
	if (self.state == UIGestureRecognizerStateChanged)
		return @"UIGestureRecognizerStateChanged";
	if (self.state == UIGestureRecognizerStateCancelled)
		return @"UIGestureRecognizerStateCancelled";
	if (self.state == UIGestureRecognizerStateFailed)
		return @"UIGestureRecognizerStateFailed";
	if (self.state == UIGestureRecognizerStateRecognized)
		return @"UIGestureRecognizerStateRecognized";
	return @"Unknown state";
}

/**
 * To be written
 * \param view To be written
 * \param margin To be written
 * \return To be written
 */
- (CGPoint)locationInView:(UIView *)view margin:(UIEdgeInsets)margin {
	CGPoint point = [self locationInView:view];
	point.x -= margin.left;
	point.y -= margin.top;
	return point;
}

@end

/**
 * To be written
 */
@implementation UITouch (UZTextView)

/**
 * To be written
 * \param view To be written
 * \param margin To be written
 * \return To be written
 */
- (CGPoint)locationInView:(UIView *)view margin:(UIEdgeInsets)margin {
	CGPoint point = [self locationInView:view];
	point.x -= margin.left;
	point.y -= margin.top;
	return point;
}

@end

@implementation UZTextView

#pragma mark - Class method to estimate attributed string size

+ (CGSize)sizeForAttributedString:(NSAttributedString*)attributedString withBoundWidth:(CGFloat)width __attribute__((deprecated)){
	// CoreText
	CTFramesetterRef _framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
	CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter,
																	CFRangeMake(0, attributedString.length),
																	NULL,
																	CGSizeMake(width, CGFLOAT_MAX),
																	NULL);
	CFRelease(_framesetter);
	return frameSize;
}

+ (CGSize)sizeForAttributedString:(NSAttributedString*)attributedString withBoundWidth:(CGFloat)width margin:(UIEdgeInsets)margin {
	// CoreText
	CTFramesetterRef _framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
	CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter,
																	CFRangeMake(0, attributedString.length),
																	NULL,
																	CGSizeMake(width - (margin.left + margin.right), CGFLOAT_MAX),
																	NULL);
	frameSize.height += (margin.top + margin.bottom);
	CFRelease(_framesetter);
	return frameSize;
}

- (void)prepareForReuse {
	_lastLayoutWidth = 0;
	_status = UZTextViewNoSelection;
	_head = 0;
	_tail = 0;
	_headWhenBegan = 0;
	_tailWhenBegan = 0;
	
	_leftCursor.hidden = YES;
	_rightCursor.hidden = YES;
	_locationWhenTapBegan = CGPointZero;
	
	SAFE_CFRELEASE(_tokenizer);
}

- (NSDictionary*)attributesAtPoint:(CGPoint)point {
    if (_scale != 1) {
        point.x /= _scale;
        point.y /= _scale;
    }
    
    __block NSRange resultRange = NSMakeRange(0, 0);
    
    _tappedLinkAttribute = nil;
    
    CFIndex index = [self indexForPoint:point];
    if (index == kCFNotFound)
        return nil;
    
    NSDictionary *attribute = [self.attributedString attributesAtIndex:index effectiveRange:&resultRange];
    CGRect rect = [self circumscribingRectForStringFromIndex:resultRange.location toIndex:resultRange.location + resultRange.length - 1];
    
    if (attribute[NSLinkAttributeName]) {
        NSMutableDictionary *attr = [NSMutableDictionary dictionaryWithDictionary:attribute];
        attr[UZTextViewClickedRect] = [NSValue valueWithCGRect:rect];
        return attr;
    }
    
    return nil;
}

- (BOOL)isSelectingAnyText {
    return (_status > 0);
}

- (void)selectAll {
    [self setSelectedRange:NSMakeRange(0, self.attributedString.length)];
}

#pragma mark - Setter and getter

- (void)setScale:(CGFloat)value {
    _scale = value;
    _longPressGestureRecognizer.enabled = (_scale == 1);
}

- (void)setAttributedString:(NSMutableAttributedString *)attributedString {
	[self prepareForReuse];
	_attributedString = attributedString;
	
	[self updateLayout];
	[self setNeedsDisplay];
}

- (NSRange)selectedRange {
	return NSMakeRange(_head, _tail - _head + 1);
}

- (void)setHighlightRanges:(NSArray *)highlightRanges {
	_highlightRanges = [highlightRanges copy];
	[self setNeedsDisplay];
}

- (void)setSelectedRange:(NSRange)selectedRange {
	if (selectedRange.location >= self.attributedString.length)
		return;
	if (selectedRange.length > self.attributedString.length || selectedRange.location + selectedRange.length - 1 <= 0)
		return;
	_head = selectedRange.location;
	_tail = selectedRange.location + selectedRange.length - 1;
	_status = UZTextViewSelected;
	[self setCursorHidden:NO];
	[self setNeedsDisplay];
#if !defined(TARGET_OS_TV)
	[self showUIMenu];
#endif
}

- (void)setMinimumPressDuration:(CFTimeInterval)minimumPressDuration {
	_minimumPressDuration = minimumPressDuration;
	_longPressGestureRecognizer.minimumPressDuration = minimumPressDuration;
}

- (CFTimeInterval)minimumPressDuration {
	return _longPressGestureRecognizer.minimumPressDuration;
}

@end

@implementation UZTextView(Internal)

#pragma mark - Instance method

- (void)setCursorHidden:(BOOL)hidden {
	// Update cursor's frame
	CGRect leftFrame = [self fragmentRectForCursorAtIndex:_head side:UZTextViewLeftEdge];
	leftFrame.origin.x += _margin.left;
	leftFrame.origin.y += _margin.top;
	[_leftCursor setFrame:leftFrame];
	CGRect rightFrame = [self fragmentRectForCursorAtIndex:_tail side:UZTextViewRightEdge];
	rightFrame.origin.x += _margin.left;
	rightFrame.origin.y += _margin.top;
	[_rightCursor setFrame:rightFrame];
	
	// Update cursor appearance
	_leftCursor.hidden = hidden;
	_rightCursor.hidden = hidden;
	
	// Enable/disable gesture recognizer
	_longPressGestureRecognizer.enabled = hidden;
}


- (void)updateLayout {
    if (_lastLayoutWidth == (self.frame.size.width - (_margin.left + _margin.right))) {
        return;
    }
    
    // CoreText
    SAFE_CFRELEASE(_framesetter);
    SAFE_CFRELEASE(_frame);
    
    CFAttributedStringRef p = (__bridge CFAttributedStringRef)_attributedString;
    if (p) {
        _framesetter = CTFramesetterCreateWithAttributedString(p);
    }
    else {
        p = CFAttributedStringCreate(NULL, CFSTR(""), NULL);
        _framesetter = CTFramesetterCreateWithAttributedString(p);
        CFRelease(p);
    }
    
    _lastLayoutWidth = self.frame.size.width - (_margin.left + _margin.right);
    
    if (_scale != 1) {
        _lastLayoutWidth = CGFLOAT_MAX;
    }
    
    CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(_framesetter,
                                                                    CFRangeMake(0, _attributedString.length),
                                                                    NULL,
                                                                    CGSizeMake(_lastLayoutWidth, CGFLOAT_MAX),
                                                                    NULL);
    
    
    
    frameSize.width = _lastLayoutWidth;
    _contentRect = CGRectZero;
    _contentRect.size = frameSize;
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, _contentRect);
    _frame = CTFramesetterCreateFrame(_framesetter, CFRangeMake(0, 0), path, NULL);
    CGPathRelease(path);
    
}

#if !defined(TARGET_OS_TV)
- (void)showUIMenu {
	[[UIMenuController sharedMenuController] setTargetRect:[self circumscribingRectForStringFromIndex:_head toIndex:_tail] inView:self];
	[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
}
#endif

- (BOOL)cancelSelectedText {
	if (_status != UZTextViewNoSelection) {
		[self setCursorHidden:YES];
		_status = UZTextViewNoSelection;
		[self setNeedsDisplay];
		return YES;
	}
	return NO;
}

#pragma mark - Layout information

- (CGRect)fragmentRectForCursorAtIndex:(NSInteger)index side:(UZTextViewGlyphEdgeType)side {
	if (side == UZTextViewLeftEdge) {
		NSArray *rects = [self fragmentRectsForGlyphFromIndex:index toIndex:index];
		CGRect rect = CGRectZero;
		if ([rects count]) {
			rect = [[rects objectAtIndex:0] CGRectValue];
		}
		return [UZCursorView cursorRectWithEdgeRect:rect cursorDirection:UZTextViewUpCursor];
	}
	else {
		NSArray *rects = [self fragmentRectsForGlyphFromIndex:index toIndex:index];
		CGRect rect = CGRectZero;
		if ([rects count]) {
			rect = [[rects objectAtIndex:0] CGRectValue];
			rect.origin.x += rect.size.width;
		}
		return [UZCursorView cursorRectWithEdgeRect:rect cursorDirection:UZTextViewDownCursor];
	}
}

- (NSArray*)fragmentRectsForGlyphFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
	if (!(fromIndex <= toIndex && fromIndex >=0 && toIndex >=0))
		return @[];
	
	CFArrayRef lines = CTFrameGetLines(_frame);
	CFIndex lineCount = CFArrayGetCount(lines);
	CGPoint lineOrigins[lineCount];
	CTFrameGetLineOrigins(_frame, CFRangeMake(0, 0), lineOrigins);
	
	NSMutableArray *fragmentRects = [NSMutableArray array];
	
	NSRange range = NSMakeRange(fromIndex, toIndex - fromIndex + 1);
	
	if (range.length <= 0)
		range.length = 1;
	
	for (NSInteger index = 0; index < lineCount; index++) {
		CGPoint origin = lineOrigins[index];
		CTLineRef line = CFArrayGetValueAtIndex(lines, index);
		
		CGRect rect = CGRectZero;
		CFRange stringRange = CTLineGetStringRange(line);
		NSRange intersectionRange = NSIntersectionRange(range, NSMakeRange(stringRange.location, stringRange.length));
		CGFloat ascent;
		CGFloat descent;
		CGFloat leading;
		CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
		
		CGRect lineRect = CGRectMake(origin.x,
									 ceilf(origin.y - descent),
									 width,
									 ceilf(ascent + descent));
		lineRect.origin.y = _contentRect.size.height - CGRectGetMaxY(lineRect);
		
		if (intersectionRange.length > 0) {
			CGFloat startOffset = CTLineGetOffsetForStringIndex(line, intersectionRange.location, NULL);
			CGFloat endOffset = CTLineGetOffsetForStringIndex(line, NSMaxRange(intersectionRange), NULL);
			
			rect = lineRect;
			rect.origin.x += startOffset;
			rect.size.width -= (rect.size.width - endOffset);
			rect.size.width = rect.size.width - startOffset;
			[fragmentRects addObject:[NSValue valueWithCGRect:rect]];
		}
	}
	return [NSArray arrayWithArray:fragmentRects];
}

- (CGRect)circumscribingRectForStringFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
	NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:fromIndex toIndex:toIndex];
	CGRect unifiedRect = [[fragmentRects objectAtIndex:0] CGRectValue];
	for (NSValue *rectValue in fragmentRects) {
		unifiedRect = CGRectUnion(unifiedRect, [rectValue CGRectValue]);
	}
	return unifiedRect;
}

#pragma mark - Draw

- (void)drawSelectedLinkFragments {
	NSRange range;
	if (CGPointEqualToPoint(_locationWhenTapBegan, CGPointZero))
		return;
	NSInteger tappedIndex = [self indexForPoint:_locationWhenTapBegan];
	NSDictionary *dict = [self.attributedString attributesAtIndex:tappedIndex effectiveRange:&range];
	if (dict[NSLinkAttributeName]) {
		NSArray *rects = [self fragmentRectsForGlyphFromIndex:tappedIndex toIndex:tappedIndex+1];
		CGRect rect = CGRectZero;
		if ([rects count]) {
			rect = [[rects objectAtIndex:0] CGRectValue];
			rect.size.width = 0;
		}
		
		if (CGRectContainsPoint(rect, _locationWhenTapBegan)) {
			CGContextRef context = UIGraphicsGetCurrentContext();
			
			[[self.tintColor colorWithAlphaComponent:_tintAlpha] setFill];
			
			NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:range.location toIndex:range.location + range.length - 1];
			
			for (NSValue *rectValue in fragmentRects) {
				CGContextFillRect(context, [rectValue CGRectValue]);
			}
		}
	}
}

- (void)drawSelectedTextFragmentRectsFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex color:(UIColor*)color {
	// Set drawing color
	[color setFill];
	CGContextRef context = UIGraphicsGetCurrentContext();
	NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:fromIndex toIndex:toIndex];
	for (NSValue *rectValue in fragmentRects) {
		CGContextFillRect(context, [rectValue CGRectValue]);
	}
}

- (void)drawStrikethroughLine {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.attributedString enumerateAttribute:NSStrikethroughStyleAttributeName inRange:NSMakeRange(0, self.attributedString.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:[NSNumber class]]) {
            // obtain and set line width from value
            [[UIColor blackColor] setStroke];
            CGContextSetLineWidth(context, [value doubleValue]);
            
            // draw horizontal lines through the center of fragrmaent rectangles as strike through lines
            NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:range.location toIndex:range.location+range.length];
            for (NSValue *rectValue in fragmentRects) {
                CGRect rect = [rectValue CGRectValue];
                CGFloat y = CGRectGetMidY(rect);
                CGContextMoveToPoint(context, rect.origin.x, y);
                CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, y);
                CGContextDrawPath(context, kCGPathStroke);
            }
        }
    }];
}

- (void)drawBackgroundColor {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.attributedString enumerateAttribute:NSBackgroundColorAttributeName inRange:NSMakeRange(0, self.attributedString.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:[UIColor class]]) {
            // obtain and set line width from value
            UIColor *backgroundColor = value;
            [backgroundColor setFill];
            
            // draw horizontal lines through the center of fragrmaent rectangles as strike through lines
            NSArray *fragmentRects = [self fragmentRectsForGlyphFromIndex:range.location toIndex:range.location+range.length];
            for (NSValue *rectValue in fragmentRects) {
                CGRect rect = [rectValue CGRectValue];
                CGContextFillRect(context, rect);
            }
        }
    }];
}

- (void)drawStringRectForDebug {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CFArrayRef lines = CTFrameGetLines(_frame);
	CFIndex lineCount = CFArrayGetCount(lines);
	CGPoint lineOrigins[lineCount];
	CTFrameGetLineOrigins(_frame, CFRangeMake(0, 0), lineOrigins);
	
	for (NSInteger index = 0; index < lineCount; index++) {
		CGPoint origin = lineOrigins[index];
		CTLineRef line = CFArrayGetValueAtIndex(lines, index);
		
		CGFloat ascent;
		CGFloat descent;
		CGFloat leading;
		CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
		
		CGRect lineRect = CGRectMake(origin.x,
									 ceilf(origin.y - descent),
									 width,
									 ceilf(ascent + descent));
		lineRect.origin.y = _contentRect.size.height - CGRectGetMaxY(lineRect);
		CGContextStrokeRect(context, lineRect);
	}
}

- (void)drawContent {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
#ifdef _UZTEXTVIEW_DEBUG_
    [[UIColor redColor] setStroke];
    CGContextStrokeRect(context, self.bounds);
    [[UIColor blueColor] setStroke];
    CGContextStrokeRect(context, UIEdgeInsetsInsetRect(self.bounds, _margin));
#endif
    
    CGContextTranslateCTM(context, _margin.left, _margin.top);
    
    if (_scale != 1)
        CGContextScaleCTM(context, _scale, _scale);
    
    // draw text
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, _contentRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CTFrameDraw(_frame, context);
    CGContextRestoreGState(context);
    
#ifdef _UZTEXTVIEW_DEBUG_
    [self drawStringRectForDebug];
#endif
    
    // draw strike through line
    [self drawStrikethroughLine];
    
    // draw hightlighted text
    for (NSValue *value in _highlightRanges) {
        NSRange range = [value rangeValue];
        [self drawSelectedTextFragmentRectsFromIndex:range.location toIndex:range.location + range.length - 1 color:[[UIColor yellowColor] colorWithAlphaComponent:0.5]];
    }
    // draw selected strings
    if (_status > 0)
        [self drawSelectedTextFragmentRectsFromIndex:_head
                                             toIndex:_tail
                                               color:[self.tintColor colorWithAlphaComponent:_tintAlpha]];
    
    // draw tapped link range background
    if (_tappedLinkRange.length > 0)
        [self drawSelectedTextFragmentRectsFromIndex:_tappedLinkRange.location
                                             toIndex:_tappedLinkRange.location + _tappedLinkRange.length - 1
                                               color:[self.tintColor colorWithAlphaComponent:_tintAlpha]];
}

#pragma mark - UILongPressGestureDelegate

- (void)didChangeLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (_tappedLinkRange.length > 0) {
            gestureRecognizer.enabled = NO;
            gestureRecognizer.enabled = YES;
        }
        else {
            [self setSelectionWithPoint:[gestureRecognizer locationInView:self margin:_margin]];
            _status = UZTextViewSelected;
            [self setCursorHidden:YES];
            [self setNeedsDisplay];
            [_loupeView setVisible:YES animated:YES];
            [_loupeView updateAtLocation:[gestureRecognizer locationInView:self] textView:self];
        }
	}
    else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		[self setSelectionWithPoint:[gestureRecognizer locationInView:self margin:_margin]];
		[self setCursorHidden:YES];
		[self setNeedsDisplay];
		[_loupeView setVisible:YES animated:YES];
		[_loupeView updateAtLocation:[gestureRecognizer locationInView:self] textView:self];
	}
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled || gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        if (_tappedLinkRange.length > 0) {
            if ([self.delegate respondsToSelector:@selector(textView:didLongTapLinkAttribute:)]) {
                NSRange resultRange = NSMakeRange(0, 0);
                CFIndex index = _tappedLinkRange.location;
                NSDictionary *attribute = [self.attributedString attributesAtIndex:index effectiveRange:&resultRange];
                [self.delegate textView:self didLongTapLinkAttribute:attribute];
            }
        }
        else {
            [self setCursorHidden:NO];
            [self setNeedsDisplay];
            [_loupeView setVisible:NO animated:YES];
            [_loupeView updateAtLocation:[gestureRecognizer locationInView:self] textView:self];
            [self becomeFirstResponder];
    #if !defined(TARGET_OS_TV)
            [self showUIMenu];
    #endif
        }
	}
}

#pragma mark - Preparation

- (void)prepareForInitialization {
	// init invaliables
	_cursorMargin = 10;
	_tintAlpha = 0.5;
	_durationToCancelSuperViewScrolling = 0.25;
    _scale = 1;
	
	_longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didChangeLongPressGesture:)];
	_longPressGestureRecognizer.minimumPressDuration = 0.5;
	[self addGestureRecognizer:_longPressGestureRecognizer];
	
	// Initialization code
	_loupeView = [[UZLoupeView alloc] initWithRadius:60];
	_loupeView.textViewBackgroundColor = self.backgroundColor;
	[self addSubview:_loupeView];
	
	_leftCursor = [[UZCursorView alloc] initWithCursorDirection:UZTextViewUpCursor];
	_leftCursor.userInteractionEnabled = NO;
	[self addSubview:_leftCursor];
	
	_rightCursor = [[UZCursorView alloc] initWithCursorDirection:UZTextViewDownCursor];
	_rightCursor.userInteractionEnabled = NO;
	[self addSubview:_rightCursor];

#if !defined(TARGET_OS_TV)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerDidHideMenuNotification:) name:UIMenuControllerDidHideMenuNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
#endif
}

#pragma mark - CoreText

- (NSRange)rangeOfLinkStringAtPoint:(CGPoint)point {
	__block NSRange resultRange = NSMakeRange(0, 0);
	
	_tappedLinkAttribute = nil;
	
	CFIndex index = [self indexForPoint:point];
	if (index == kCFNotFound)
		return resultRange;
	
	_tappedLinkAttribute = [self.attributedString attributesAtIndex:index effectiveRange:&resultRange];
	if (!_tappedLinkAttribute[NSLinkAttributeName])
		resultRange = NSMakeRange(0, 0);
	return resultRange;
}

- (void)setSelectionWithPoint:(CGPoint)point {
	CFIndex index = [self indexForPoint:point];
	if (index == kCFNotFound)
		return;
	
	CFStringRef string = (__bridge CFStringRef)self.attributedString.string;
	CFRange range = CFRangeMake(0, CFStringGetLength(string));
	
	
	if (_tokenizer == NULL) {
		_tokenizer = CFStringTokenizerCreate(
											 NULL,
											 string,
											 range,
											 kCFStringTokenizerUnitWordBoundary,
											 NULL);
	}
	CFStringTokenizerTokenType tokenType = CFStringTokenizerGoToTokenAtIndex(_tokenizer, 0);
	while (tokenType != kCFStringTokenizerTokenNone || range.location + range.length < CFStringGetLength(string)) {
		range = CFStringTokenizerGetCurrentTokenRange(_tokenizer);
		
		if (range.location == kCFNotFound) {
			_head = index;
			_tail = index;
			break;
		}
		
		CFIndex first = range.location;
		CFIndex second = range.location + range.length - 1;
		if (first != kCFNotFound && first <= index && index <= second) {
			_head = first;
			_tail = second;
			break;
		}
		tokenType = CFStringTokenizerAdvanceToNextToken(_tokenizer);
	}
}

- (CFIndex)indexForPoint:(CGPoint)point {
    CFArrayRef lines = CTFrameGetLines(_frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, 0), lineOrigins);
    
    CGRect previousLineRect = CGRectZero;
    
    for (NSInteger index = 0; index < lineCount; index++) {
        CGPoint origin = lineOrigins[index];
        CTLineRef line = CFArrayGetValueAtIndex(lines, index);
        
        CFRange lineCFRange = CTLineGetStringRange(line);
        NSRange lineRange = NSMakeRange(lineCFRange.location, lineCFRange.length);
        CGFloat ascent;
        CGFloat descent;
        CGFloat leading;
        CGFloat width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        
        CGRect lineRect = CGRectMake(origin.x,
                                     ceilf(origin.y - descent),
                                     width,
                                     ceilf(ascent + descent));
        lineRect.origin.y = _contentRect.size.height - CGRectGetMaxY(lineRect);
        
        CGRect temp = lineRect;
        lineRect.size.height += (lineRect.origin.y - previousLineRect.origin.y - previousLineRect.size.height);
        lineRect.origin.y = previousLineRect.origin.y + previousLineRect.size.height;
        previousLineRect = temp;
        
        // UZTextViewとの変更点
        CGRect tapRect = CGRectInset(CGRectMake(point.x, point.y, 0, 0), -10, -10);
        
        if (CGRectIntersectsRect(lineRect, tapRect)) {
            CFIndex result = CTLineGetStringIndexForPosition(line, point);
            if (result != kCFNotFound && NSLocationInRange(result, lineRange)) {
                if (result > 1)
                    return (result - 1);		// UZTextViewとの変更点
                return result;
            }
        }
        
        CGRect marginArea = lineRect;
        marginArea.origin.x = _contentRect.origin.x;
        marginArea.size.width = _contentRect.size.width;
        
        if (CGRectContainsPoint(marginArea, point)) {
            return lineRange.location + lineRange.length - 1;
        }
    }
    return kCFNotFound;
}

#pragma mark - Touch event(Override)

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
touch = YES;
	UITouch *touch = [touches anyObject];
    [self setNeedsDisplay];
#if !defined(TARGET_OS_TV)
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
#endif
	
	_headWhenBegan = _head;
	_tailWhenBegan = _tail;
	if (CGRectContainsPoint([self fragmentRectForCursorAtIndex:_head side:UZTextViewLeftEdge], [touch locationInView:self margin:_margin]) && !_leftCursor.hidden && !_rightCursor.hidden) {
		if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
			[self.delegate selectionDidBeginTextView:self];
		_status = UZTextViewEditingFromSelection;
		[_loupeView setVisible:YES animated:YES];
		[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
		[self setCursorHidden:NO];
	}
	else if (CGRectContainsPoint([self fragmentRectForCursorAtIndex:_tail side:UZTextViewRightEdge], [touch locationInView:self margin:_margin]) && !_leftCursor.hidden && !_rightCursor.hidden) {
		if ([self.delegate respondsToSelector:@selector(selectionDidBeginTextView:)])
            [self.delegate selectionDidBeginTextView:self];
		_status = UZTextViewEditingToSelection;
		[_loupeView setVisible:YES animated:YES];
		[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
		[self setCursorHidden:NO];
	}
    else {
        // UZTextViewとの変更点
        CGPoint p = [touch locationInView:self margin:_margin];
        if (_scale != 1) {
            p.x /= _scale;
            p.y /= _scale;
        }
        _tappedLinkRange = [self rangeOfLinkStringAtPoint:p];
        [self setNeedsDisplay];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
    
    // Z方向への押し込みを無視する
    if (CGPointEqualToPoint([touch locationInView:self], [touch previousLocationInView:self]))
        return;
    
    if (_status == UZTextViewEditingFromSelection) {
		NSInteger index = [self indexForPoint:[touch locationInView:self margin:_margin]];
		[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
        if (index != kCFNotFound) {
            if (index < _tailWhenBegan) {
                _head = index;
            } else {
                _head = _tailWhenBegan;
                _tail = index;
            }
		}
		[self setCursorHidden:NO];
	}
    else if (_status == UZTextViewEditingToSelection) {
		NSInteger index = [self indexForPoint:[touch locationInView:self margin:_margin]];
		[_loupeView updateAtLocation:[touch locationInView:self] textView:self];
		if (index != kCFNotFound) {
            if (index > _headWhenBegan) {
                _tail = index;
            } else {
                _tail = _headWhenBegan;
                _head = index;
            }
		}
		[self setCursorHidden:NO];
	}
	_tappedLinkRange = NSMakeRange(0, 0);
	_tappedLinkAttribute = nil;
	[self setNeedsDisplay];
}

- (BOOL) isTouching {
    return touch;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
touch = NO;
	if (_longPressGestureRecognizer.state == UIGestureRecognizerStatePossible) {
		if (_tappedLinkAttribute[NSLinkAttributeName] && _tappedLinkRange.length) {
			if ([self.delegate respondsToSelector:@selector(textView:didClickLinkAttribute:)]) {
				[self.delegate textView:self didClickLinkAttribute:_tappedLinkAttribute];
			}
			_tappedLinkRange = NSMakeRange(0, 0);
			_tappedLinkAttribute = nil;
			[self setNeedsDisplay];
			return;
		}
	}
	
	if (_status == UZTextViewEditingFromSelection) {
		[_loupeView setVisible:NO animated:YES];
        [self becomeFirstResponder];
#if !defined(TARGET_OS_TV)
        [self showUIMenu];
#endif
		_status = UZTextViewSelected;
	}
	else if (_status == UZTextViewEditingToSelection) {
		[_loupeView setVisible:NO animated:YES];
        [self becomeFirstResponder];
#if !defined(TARGET_OS_TV)
        [self showUIMenu];
#endif
		_status = UZTextViewSelected;
	}
	else if (_longPressGestureRecognizer.state != UIGestureRecognizerStateBegan) {
		if (_tappedLinkRange.length == 0) {
			if (_status != UZTextViewNoSelection) {
				NSInteger tappedCharacterIndex = [self indexForPoint:[[touches anyObject] locationInView:self margin:_margin]];
				if (_head <= tappedCharacterIndex && tappedCharacterIndex <= _tail) {
                    // show uimenu if user tapped selected text range.
#if !defined(TARGET_OS_TV)
					[self showUIMenu];
#endif
				}
				else {
					// selection is cancelled when some strings are selected.
					[self cancelSelectedText];
				}
			}
			else {
				// tells the event to tap any region which has not include any links to the delegtae
				// when any text has not been selected.
				if ([self.delegate respondsToSelector:@selector(didTapTextDoesNotIncludeLinkTextView:)]) {
					[self.delegate didTapTextDoesNotIncludeLinkTextView:self];
				}
			}
		}
	}
	
	// for unlocking parent view's scrolling
	if ([self.delegate respondsToSelector:@selector(selectionDidEndTextView:)])
		[self.delegate selectionDidEndTextView:self];
	
	// clear tapping location
	_locationWhenTapBegan = CGPointZero;
	_tappedLinkRange = NSMakeRange(0, 0);
	
	[self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
}

#pragma mark - NSNotification

#if !defined(TARGET_OS_TV)
- (void)menuControllerDidHideMenuNotification:(NSNotification*)notification {
	[[UIMenuController sharedMenuController] setMenuItems:nil];
}
#endif

- (void)applicationDidChangeStatusBarOrientationNotification:(NSNotification*)notification {
	[_loupeView setVisible:NO animated:NO];
	[_loupeView updateAtLocation:CGPointZero textView:self];
}

#pragma mark - for UIMenuController(Override)

- (BOOL)resignFirstResponder {
	return [super resignFirstResponder];
}

BOOL touch;

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)copy:(id)sender {
#if !defined(TARGET_OS_TV)
	[UIPasteboard generalPasteboard].string = [self.attributedString.string substringWithRange:self.selectedRange];
#endif
}

- (void)selectAll:(id)sender {
	[self setSelectedRange:NSMakeRange(0, self.attributedString.length)];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(copy:))
		return YES;
	if (action == @selector(selectAll:))
		return YES;
	return NO;
}

#pragma mark - Setter and getter(Override)

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	[self updateLayout];
	[self setNeedsDisplay];
}

- (void)setBounds:(CGRect)bounds {
	[super setBounds:bounds];
	[self updateLayout];
	[self setNeedsDisplay];
}

#pragma mark - Override

- (void)dealloc {
    SAFE_CFRELEASE(_frame);
    SAFE_CFRELEASE(_framesetter);
    SAFE_CFRELEASE(_tokenizer);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
	[super setBackgroundColor:backgroundColor];
	_loupeView.textViewBackgroundColor = backgroundColor;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.bounds, point)) {
		CGPoint pointForUZTextViewContent = point;
		pointForUZTextViewContent.x -= _margin.left;
		pointForUZTextViewContent.y -= _margin.top;
		NSMutableArray *rects = [NSMutableArray array];
		[rects addObjectsFromArray:[self fragmentRectsForGlyphFromIndex:0 toIndex:self.attributedString.length-1]];
		[rects addObject:[NSValue valueWithCGRect:[self fragmentRectForCursorAtIndex:_head side:UZTextViewLeftEdge]]];
		[rects addObject:[NSValue valueWithCGRect:[self fragmentRectForCursorAtIndex:_tail side:UZTextViewRightEdge]]];

		for (NSValue *rectValue in rects) {
			if (CGRectContainsPoint([rectValue CGRectValue], pointForUZTextViewContent))
				return [super hitTest:point withEvent:event];
		}
		if (_scale != 1) {
			pointForUZTextViewContent.x /= _scale;
			pointForUZTextViewContent.y /= _scale;
		}
        
        for (NSValue *rectValue in rects) {
            if (CGRectContainsPoint([rectValue CGRectValue], pointForUZTextViewContent))
                return [super hitTest:point withEvent:event];
        }
        if (_status != UZTextViewNoSelection) {
            // does not pass tap event to the other view
            // when some text is selected.
            return [super hitTest:point withEvent:event];
        }
    }
    return nil;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	[self setNeedsDisplay];
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self)
		[self prepareForInitialization];
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self)
		[self prepareForInitialization];
	return self;
}

- (void)drawRect:(CGRect)rect {
	// draw main content
	[self drawContent];
}

@end
