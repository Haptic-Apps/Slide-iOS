//
//  STPopupPreviewRecognizer.m
//  STPopupPreview
//
//  Created by Kevin Lin on 22/5/16.
//  Copyright © 2016 Sth4Me. All rights reserved.
//

#import "STPopupPreviewRecognizer.h"
#import <STPopup/STPopup.h>

CGFloat const STPopupPreviewActionSheetButtonHeight = 57;
CGFloat const STPopupPreviewActionSheetSpacing = 10;
CGFloat const STPopupPreviewShowActionsOffset = 30;

@interface STPopupPreviewAction ()

@property (nonatomic, copy, readonly) void (^handler)(STPopupPreviewAction *, UIViewController *);

- (instancetype)initWithTitle:(NSString *)title style:(STPopupPreviewActionStyle)style handler:(void (^)(STPopupPreviewAction *, UIViewController *))handler;

@end

@implementation STPopupPreviewAction

- (instancetype)initWithTitle:(NSString *)title style:(STPopupPreviewActionStyle)style handler:(void (^)(STPopupPreviewAction *, UIViewController *))handler
{
    if (self = [super init]) {
        _title = title;
        _style = style;
        _handler = [handler copy];
    }
    return self;
}

+ (instancetype)actionWithTitle:(NSString *)title style:(STPopupPreviewActionStyle)style handler:(void (^)(STPopupPreviewAction *, UIViewController *))handler;
{
    return [[STPopupPreviewAction alloc] initWithTitle:title style:style handler:handler];
}

@end

@class STPopupPreviewActionSheet;

@protocol STPopupPreviewActionSheetDelegate <NSObject>

- (void)popupPreviewActionSheet:(STPopupPreviewActionSheet *)actionSheet didSelectAction:(STPopupPreviewAction *)action;

@end

/**
 The action sheet for internal use.
 */
@interface STPopupPreviewActionSheet : UIView

@property (nonatomic, weak) id<STPopupPreviewActionSheetDelegate> delegate;
@property (nonatomic, strong, readonly) NSArray<STPopupPreviewAction *> *actions;

- (instancetype)initWithActions:(NSArray<STPopupPreviewAction *> *)actions;

@end

@implementation STPopupPreviewActionSheet
{
    UIView *_topContainerView;
    UIView *_bottomContainerView;
}

- (instancetype)initWithActions:(NSArray<STPopupPreviewAction *> *)actions
{
    if (self = [super init]) {
        _actions = actions;
        NSMutableArray<STPopupPreviewAction *> *topActions = [NSMutableArray new];
        NSMutableArray<STPopupPreviewAction *> *bottomActions = [NSMutableArray new];
        for (STPopupPreviewAction *action in actions) {
            switch (action.style) {
                case STPopupPreviewActionStyleDefault:
                case STPopupPreviewActionStyleDestructive:
                    [topActions addObject:action];
                    break;
                case STPopupPreviewActionStyleCancel:
                    [bottomActions addObject:action];
                    break;
                default:
                    break;
            }
        }
        
        if (topActions.count) {
            _topContainerView = [self createContainerView];
            [self addSubview:_topContainerView];
            for (STPopupPreviewAction *action in topActions) {
                UIButton *button = [self createActionButtonWithAction:action showsSeparator:action != topActions.lastObject];
                [_topContainerView addSubview:button];
            }
        }
        if (bottomActions.count) {
            _bottomContainerView = [self createContainerView];
            [self addSubview:_bottomContainerView];
            for (STPopupPreviewAction *action in bottomActions) {
                UIButton *button = [self createActionButtonWithAction:action showsSeparator:action != topActions.lastObject];
                [_bottomContainerView addSubview:button];
            }
        }
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat spacing = STPopupPreviewActionSheetSpacing;
    CGFloat buttonHeight = STPopupPreviewActionSheetButtonHeight;
    _topContainerView.frame = CGRectMake(spacing, spacing, self.superview.bounds.size.width - spacing * 2, _topContainerView.subviews.count * buttonHeight);
    _bottomContainerView.frame = CGRectMake(spacing, _topContainerView.frame.origin.y + _topContainerView.frame.size.height + spacing, self.superview.bounds.size.width - spacing * 2, _bottomContainerView.subviews.count * buttonHeight);
    [self layoutContainerView:_topContainerView];
    [self layoutContainerView:_bottomContainerView];
}

- (void)layoutContainerView:(UIView *)containerView
{
    for (UIView *subview in containerView.subviews) {
        subview.frame = CGRectMake(0, STPopupPreviewActionSheetButtonHeight * [containerView.subviews indexOfObject:subview], containerView.frame.size.width, STPopupPreviewActionSheetButtonHeight);
    }
}

- (void)sizeToFit
{
    NSAssert(self.superview, @"%@ of %@ can only be called after it's added to a superview", NSStringFromSelector(_cmd), NSStringFromClass(self.class));
    
    CGRect frame = self.frame;
    frame.size.width = self.superview.frame.size.width;
    self.frame = frame;
    [self layoutIfNeeded];
    
    if (_bottomContainerView) {
        frame.size.height = _bottomContainerView.frame.origin.y + _bottomContainerView.frame.size.height + STPopupPreviewActionSheetSpacing;
    }
    else {
        frame.size.height = _topContainerView.frame.origin.y + _topContainerView.frame.size.height + STPopupPreviewActionSheetSpacing;
    }
    frame.origin = CGPointMake(0, self.superview.frame.size.height - frame.size.height);
    self.frame = frame;
}

#pragma mark - Actions

- (void)actionButtonDidTap:(UIButton *)button
{
    STPopupPreviewAction *action = self.actions[button.tag];
    [self.delegate popupPreviewActionSheet:self didSelectAction:action];
}

#pragma mark - Helpers

- (UIView *)createContainerView
{
    UIView *containerView = [UIView new];
    containerView.layer.cornerRadius = 10;
    containerView.clipsToBounds = YES;
    containerView.backgroundColor = [UIColor colorWithRed:249/255.f green:247/255.f blue:249/255.f alpha:0];
    return containerView;
}

- (UIButton *)createActionButtonWithAction:(STPopupPreviewAction *)action showsSeparator:(BOOL)showsSeparator
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.tag = [self.actions indexOfObject:action];
    [button setTitle:action.title forState:UIControlStateNormal];
    [button addTarget:self action:@selector(actionButtonDidTap:) forControlEvents:UIControlEventTouchUpInside];
    switch (action.style) {
        case STPopupPreviewActionStyleDestructive:
            [button setTitleColor:[UIColor colorWithRed:1 green:0.23 blue:0.19 alpha:1] forState:UIControlStateNormal];
        case STPopupPreviewActionStyleDefault:
            button.titleLabel.font = [UIFont systemFontOfSize:20];
            break;
        case STPopupPreviewActionStyleCancel:
            button.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        default:
            break;
    }
    if (showsSeparator) {
        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, button.frame.size.height, button.frame.size.width, 0.5)];
        separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        separatorView.backgroundColor = [UIColor colorWithRed:179/255.f green:180/255.f blue:184/255.f alpha:1];
        [button addSubview:separatorView];
    }
    return button;
}

@end

/**
 A custom view which draws the arrow indicator.
 */
@interface STPopupPreviewArrowView : UIView

@end

@implementation STPopupPreviewArrowView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.opaque = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat lineWidth = 5;
    CGFloat shadowRadius = 4;
    CGFloat width = rect.size.width - lineWidth - shadowRadius * 2;
    CGFloat height = rect.size.height - lineWidth - shadowRadius * 2;
    CGFloat x = (rect.size.width - width) / 2;
    CGFloat y = (rect.size.height - height) / 2;
    
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 0.0f), shadowRadius, [UIColor colorWithWhite:0.2 alpha:0.2].CGColor);
    
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinBevel);
    
    CGContextMoveToPoint(context, x, y + height);
    CGContextAddLineToPoint(context, x + width / 2, y);
    CGContextAddLineToPoint(context, x + width, y + height);
    
    CGContextStrokePath(context);
}

@end

@interface STPopupPreviewRecognizer () <STPopupPreviewActionSheetDelegate>

@property (nonatomic, weak) UIView *view;

@end

@implementation STPopupPreviewRecognizer
{
    __weak id<STPopupPreviewRecognizerDelegate> _delegate;
    UILongPressGestureRecognizer *_longPressGesture;
    UIPanGestureRecognizer *_panGesture;
    UITapGestureRecognizer *_tapGesture;
    STPopupController *_popupController;
    CGFloat _startPointY;
    STPopupPreviewArrowView *_arrowView;
    STPopupPreviewActionSheet *_actionSheet;
}

- (instancetype)initWithDelegate:(id<STPopupPreviewRecognizerDelegate>)deleagte
{
    if (self = [super init]) {
        _delegate = deleagte;
    }
    return self;
}

- (void)setView:(UIView *)view
{
    if (!_longPressGesture) {
        _longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
        _longPressGesture.minimumPressDuration = 0.3;
    }
    [_view removeGestureRecognizer:_longPressGesture];
    _view = view;
    [_view addGestureRecognizer:_longPressGesture];
}

#pragma mark - Helpers

- (void)dismissWithCompletion:(void(^)())completion
{
    _state = STPopupPreviewRecognizerStateNone;
    [_popupController.backgroundView removeGestureRecognizer:_panGesture];
    [_popupController.backgroundView removeGestureRecognizer:_tapGesture];
    [_popupController dismissWithCompletion:^{
        if (completion) {
            completion();
        }
        [_arrowView removeFromSuperview];
        _arrowView = nil;
        [_actionSheet removeFromSuperview];
        _actionSheet = nil;
        _panGesture = nil;
        _tapGesture = nil;
        _popupController = nil;
    }];
}

#pragma mark - Gestures

- (void)gestureAction:(UIGestureRecognizer *)gesture
{
    NSAssert(gesture == _longPressGesture || _panGesture == _panGesture, @"Gesture is not expected");
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            if (gesture == _panGesture) { // Reset _startPointY if it's from _panGesture, make sure translationY is correctly calculated
                _startPointY = [gesture locationInView:_popupController.backgroundView].y - _popupController.containerView.transform.ty;
                break;
            }
            
            UIViewController *previewViewController = [_delegate previewViewControllerForPopupPreviewRecognizer:self];
            if (!previewViewController) {
                break;
            }
            
            _popupController = [[STPopupController alloc] initWithRootViewController:previewViewController];
            _popupController.containerView.layer.cornerRadius = 15;
            _popupController.transitionStyle = STPopupTransitionStyleFade;
            _popupController.hidesCloseButton = YES;
            _popupController.navigationBarHidden = YES;
            _popupController.containerView.backgroundColor = [UIColor clearColor];
            
            UIView *backgroundContentView = nil;
            if (NSClassFromString(@"_UICustomBlurEffect")) {
                UIBlurEffect *blurEffect = [NSClassFromString(@"_UICustomBlurEffect") alloc];
                [blurEffect setValue:@3 forKey:@"blurRadius"];
                UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
                _popupController.backgroundView = blurEffectView;
                backgroundContentView = blurEffectView.contentView;
            }
            else { // Work around for iOS 7
                _popupController.backgroundView = [UIToolbar new];
                backgroundContentView = _popupController.backgroundView;
            }
            
            UIViewController *presentingViewController = [_delegate presentingViewControllerForPopupPreviewRecognizer:self];
            [_popupController presentInViewController:presentingViewController completion:^{
                _popupController.containerView.userInteractionEnabled = NO;
                _state = STPopupPreviewRecognizerStatePreviewing;
                _startPointY = [gesture locationInView:_popupController.backgroundView].y;
                
                NSArray<STPopupPreviewAction *> *actions = [_delegate previewActionsForPopupPreviewRecognizer:self];
                if (actions.count) {
                    CGFloat arrowWidth = 44;
                    CGFloat arrowHeight = 20;
                    _arrowView = [[STPopupPreviewArrowView alloc] initWithFrame:CGRectMake((_popupController.backgroundView.frame.size.width - arrowWidth) / 2, _popupController.containerView.frame.origin.y - 35, arrowWidth, arrowHeight)];
                    [backgroundContentView addSubview:_arrowView];
                    _arrowView.alpha = 0;
                    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        _arrowView.alpha = 1;
                    } completion:nil];
                    
                    _actionSheet = [[STPopupPreviewActionSheet alloc] initWithActions:actions];
                    _actionSheet.delegate = self;
                    [backgroundContentView addSubview:_actionSheet];
                    [_actionSheet sizeToFit];
                    _actionSheet.transform = CGAffineTransformMakeTranslation(0, _actionSheet.frame.size.height);
                }
                
                _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(gestureAction:)];
                [_popupController.backgroundView addGestureRecognizer:_panGesture];
                _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(containerViewDidTap)];
                [_popupController.backgroundView addGestureRecognizer:_tapGesture];
            }];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            if ((_state != STPopupPreviewRecognizerStatePreviewing && _state != STPopupPreviewRecognizerStateShowingActions) ||
                !_actionSheet) {
                break;
            }
            
            CGPoint currentPoint = [gesture locationInView:_popupController.backgroundView];
            CGFloat translationY = currentPoint.y - _startPointY;
            _popupController.containerView.transform = CGAffineTransformMakeTranslation(0, translationY);
            _arrowView.transform = _popupController.containerView.transform;
            
            if (-translationY >= STPopupPreviewShowActionsOffset) { // Start showing action sheet
                [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    _arrowView.alpha = 0;
                } completion:nil];
                
                CGFloat availableHeight = _popupController.backgroundView.frame.size.height - _popupController.containerView.frame.origin.y - _popupController.containerView.frame.size.height;
                if (_state != STPopupPreviewRecognizerStateShowingActions) {
                    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        if (availableHeight >= _actionSheet.frame.size.height) {
                            _actionSheet.transform = CGAffineTransformIdentity;
                        }
                        else {
                            _actionSheet.transform = CGAffineTransformMakeTranslation(0, _actionSheet.frame.size.height - availableHeight);
                        }
                    } completion:nil];
                }
                else {
                    if (availableHeight >= _actionSheet.frame.size.height) {
                        _actionSheet.transform = CGAffineTransformIdentity;
                    }
                    else {
                        _actionSheet.transform = CGAffineTransformMakeTranslation(0, _actionSheet.frame.size.height - availableHeight);
                    }
                }
                _state = STPopupPreviewRecognizerStateShowingActions;
            }
            else { // Dismiss action sheet
                [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    _arrowView.alpha = 1;
                    _actionSheet.transform = CGAffineTransformMakeTranslation(0, _actionSheet.frame.size.height);
                } completion:nil];
                _state = STPopupPreviewRecognizerStatePreviewing;
            }
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
            if (_state == STPopupPreviewRecognizerStateShowingActions) { // Make sure action sheet is fully showed
                CGFloat availableHeight = _popupController.backgroundView.frame.size.height - _actionSheet.frame.size.height;
                CGFloat translationY = availableHeight - _popupController.containerView.frame.size.height - (_popupController.backgroundView.frame.size.height - _popupController.containerView.frame.size.height) / 2;
                [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    if (translationY < 0) {
                        _popupController.containerView.transform = CGAffineTransformMakeTranslation(0, translationY);
                    }
                    else {
                        _popupController.containerView.transform = CGAffineTransformIdentity;
                    }
                    _arrowView.transform = _popupController.containerView.transform;
                    _actionSheet.transform = CGAffineTransformIdentity;
                } completion:nil];
            }
            else {
                [self dismissWithCompletion:nil];
            }
        }
            break;
        default:
            break;
    }
}

- (void)containerViewDidTap
{
    [self dismissWithCompletion:nil];
}

#pragma mark - STPopupPreviewActionSheetDelegate

- (void)popupPreviewActionSheet:(STPopupPreviewActionSheet *)actionSheet didSelectAction:(STPopupPreviewAction *)action
{
    [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _popupController.containerView.transform = CGAffineTransformMakeTranslation(0, -_popupController.containerView.frame.size.height - (_popupController.backgroundView.frame.size.height - _popupController.containerView.frame.size.height) / 2);
        _actionSheet.transform = CGAffineTransformMakeTranslation(0, _actionSheet.frame.size.height);
    } completion:^(BOOL finished) {
        [self dismissWithCompletion:^{
            if (action.handler) {
                action.handler(action, _popupController.topViewController);
            }
        }];
    }];
}

@end
