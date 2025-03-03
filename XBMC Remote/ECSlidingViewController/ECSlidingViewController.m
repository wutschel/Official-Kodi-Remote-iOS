//
//  ECSlidingViewController.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import "ECSlidingViewController.h"
#import "AppDelegate.h"

NSString *const ECSlidingViewUnderRightWillAppear    = @"ECSlidingViewUnderRightWillAppear";
NSString *const ECSlidingViewUnderLeftWillAppear     = @"ECSlidingViewUnderLeftWillAppear";
NSString *const ECSlidingViewUnderLeftWillDisappear  = @"ECSlidingViewUnderLeftWillDisappear";
NSString *const ECSlidingViewUnderRightWillDisappear = @"ECSlidingViewUnderRightWillDisappear";
NSString *const ECSlidingViewTopDidAnchorLeft        = @"ECSlidingViewTopDidAnchorLeft";
NSString *const ECSlidingViewTopDidAnchorRight       = @"ECSlidingViewTopDidAnchorRight";
NSString *const ECSlidingViewTopWillReset            = @"ECSlidingViewTopWillReset";
NSString *const ECSlidingViewTopDidReset             = @"ECSlidingViewTopDidReset";
#define SWIPE_LEFT_THRESHOLD -1000.0

@interface ECSlidingViewController()

@property (nonatomic, strong) UIView *topViewSnapshot;
@property (nonatomic, unsafe_unretained) CGFloat initialTouchPositionX;
@property (nonatomic, unsafe_unretained) CGFloat initialHoizontalCenter;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *resetTapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *topViewSnapshotPanGesture;
@property (nonatomic, unsafe_unretained) BOOL underLeftShowing;
@property (nonatomic, unsafe_unretained) BOOL underRightShowing;
@property (nonatomic, unsafe_unretained) BOOL topViewIsOffScreen;

- (NSUInteger)autoResizeToFillScreen;
- (UIView*)topView;
- (UIView*)underLeftView;
- (UIView*)underRightView;
- (void)adjustLayout;
- (void)updateTopViewHorizontalCenterWithRecognizer:(UIPanGestureRecognizer*)recognizer;
- (void)updateTopViewHorizontalCenter:(CGFloat)newHorizontalCenter;
- (void)topViewHorizontalCenterWillChange:(CGFloat)newHorizontalCenter;
- (void)topViewHorizontalCenterDidChange:(CGFloat)newHorizontalCenter;
- (void)addTopViewSnapshot;
- (void)removeTopViewSnapshot;
- (CGFloat)anchorRightTopViewCenter;
- (CGFloat)anchorLeftTopViewCenter;
- (CGFloat)resettedCenter;
- (CGFloat)screenWidth;
- (CGFloat)screenWidthForOrientation:(BOOL)isLandscape;
- (void)underLeftWillAppear;
- (void)underRightWillAppear;
- (void)topDidReset;
- (BOOL)topViewHasFocus;
- (void)updateUnderLeftLayout;
- (void)updateUnderRightLayout;

@end

@implementation UIViewController(SlidingViewExtension)

- (ECSlidingViewController*)slidingViewController {
    UIViewController *viewController = self.parentViewController;
    while (!(viewController == nil || [viewController isKindOfClass:[ECSlidingViewController class]])) {
        viewController = viewController.parentViewController;
    }

    return (ECSlidingViewController*)viewController;
}

@end

@implementation ECSlidingViewController

// public properties
@synthesize underLeftViewController  = _underLeftViewController;
@synthesize underRightViewController = _underRightViewController;
@synthesize topViewController        = _topViewController;
@synthesize anchorLeftPeekAmount;
@synthesize anchorRightPeekAmount;
@synthesize anchorLeftRevealAmount;
@synthesize anchorRightRevealAmount;
@synthesize underRightWidthLayout = _underRightWidthLayout;
@synthesize underLeftWidthLayout  = _underLeftWidthLayout;
@synthesize shouldAllowUserInteractionsWhenAnchored;
@synthesize shouldAddPanGestureRecognizerToTopViewSnapshot;
@synthesize resetStrategy = _resetStrategy;

// category properties
@synthesize topViewSnapshot;
@synthesize initialTouchPositionX;
@synthesize initialHoizontalCenter;
@synthesize panGesture = _panGesture;
@synthesize resetTapGesture;
@synthesize underLeftShowing   = _underLeftShowing;
@synthesize underRightShowing  = _underRightShowing;
@synthesize topViewIsOffScreen = _topViewIsOffScreen;
@synthesize topViewSnapshotPanGesture = _topViewSnapshotPanGesture;

- (void)setTopViewController:(UIViewController*)theTopViewController {
    CGRect topViewFrame = _topViewController ? _topViewController.view.frame : self.view.bounds;

    [self removeTopViewSnapshot];
    [_topViewController.view removeFromSuperview];
    [_topViewController willMoveToParentViewController:nil];
    [_topViewController removeFromParentViewController];

    _topViewController = theTopViewController;

    [self addChildViewController:self.topViewController];
    [self.topViewController didMoveToParentViewController:self];

    _topViewController.view.autoresizingMask = self.autoResizeToFillScreen;
    _topViewController.view.frame = topViewFrame;
    _topViewController.view.layer.shadowOffset = CGSizeZero;
    _topViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.layer.bounds].CGPath;

    [self.view addSubview:_topViewController.view];
}

- (void)setUnderLeftViewController:(UIViewController*)theUnderLeftViewController {
    [_underLeftViewController.view removeFromSuperview];
    [_underLeftViewController willMoveToParentViewController:nil];
    [_underLeftViewController removeFromParentViewController];

    _underLeftViewController = theUnderLeftViewController;

    if (_underLeftViewController) {
        [self addChildViewController:self.underLeftViewController];
        [self.underLeftViewController didMoveToParentViewController:self];

        [self updateUnderLeftLayout];

        [self.view insertSubview:_underLeftViewController.view atIndex:0];
    }
}

- (void)setUnderRightViewController:(UIViewController*)theUnderRightViewController {
    [_underRightViewController.view removeFromSuperview];
    [_underRightViewController willMoveToParentViewController:nil];
    [_underRightViewController removeFromParentViewController];

    _underRightViewController = theUnderRightViewController;

    if (_underRightViewController) {
        [self addChildViewController:self.underRightViewController];
        [self.underRightViewController didMoveToParentViewController:self];

        [self updateUnderRightLayout];

        [self.view insertSubview:_underRightViewController.view atIndex:0];
    }
}

- (void)setUnderLeftWidthLayout:(ECViewWidthLayout)underLeftWidthLayout {
    if (underLeftWidthLayout == ECVariableRevealWidth && self.anchorRightPeekAmount <= 0) {
        [NSException raise:@"Invalid Width Layout" format:@"anchorRightPeekAmount must be set"];
    }
    else if (underLeftWidthLayout == ECFixedRevealWidth && self.anchorRightRevealAmount <= 0) {
        [NSException raise:@"Invalid Width Layout" format:@"anchorRightRevealAmount must be set"];
    }

    _underLeftWidthLayout = underLeftWidthLayout;
}

- (void)setUnderRightWidthLayout:(ECViewWidthLayout)underRightWidthLayout {
    if (underRightWidthLayout == ECVariableRevealWidth && self.anchorLeftPeekAmount <= 0) {
        [NSException raise:@"Invalid Width Layout" format:@"anchorLeftPeekAmount must be set"];
    }
    else if (underRightWidthLayout == ECFixedRevealWidth && self.anchorLeftRevealAmount <= 0) {
        [NSException raise:@"Invalid Width Layout" format:@"anchorLeftRevealAmount must be set"];
    }

    _underRightWidthLayout = underRightWidthLayout;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shouldAllowUserInteractionsWhenAnchored = NO;
    self.shouldAddPanGestureRecognizerToTopViewSnapshot = NO;
    self.resetTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetTopView)];
    _panGesture          = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateTopViewHorizontalCenterWithRecognizer:)];
    self.resetTapGesture.enabled = NO;
    self.resetStrategy = ECTapping | ECPanning;

    self.topViewSnapshot = [[UIView alloc] initWithFrame:self.topView.bounds];
    self.topViewSnapshot.autoresizingMask = self.autoResizeToFillScreen;
    [self.topViewSnapshot addGestureRecognizer:self.resetTapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.topView.layer.shadowOffset = CGSizeZero;
    self.topView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.layer.bounds].CGPath;
    [self adjustLayout];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.topView.layer.shadowPath = nil;
    self.topView.layer.shouldRasterize = YES;
    if (![self topViewHasFocus]) {
        [self removeTopViewSnapshot];
    }
    [self adjustLayout];

    [coordinator animateAlongsideTransition:nil
    completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.topView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.layer.bounds].CGPath;
        self.topView.layer.shouldRasterize = NO;
        if (![self topViewHasFocus]) {
            [self addTopViewSnapshot];
        }
    }];
}

- (void)setResetStrategy:(ECResetStrategy)theResetStrategy {
    _resetStrategy = theResetStrategy;
    if (_resetStrategy & ECTapping) {
        self.resetTapGesture.enabled = YES;
    }
    else {
        self.resetTapGesture.enabled = NO;
    }
}

- (void)adjustLayout {
    self.topViewSnapshot.frame = self.topView.bounds;

    if ([self underRightShowing] && ![self topViewIsOffScreen]) {
        [self updateUnderRightLayout];
        [self updateTopViewHorizontalCenter:self.anchorLeftTopViewCenter];
    }
    else if ([self underRightShowing] && [self topViewIsOffScreen]) {
        [self updateUnderRightLayout];
        [self updateTopViewHorizontalCenter:-self.resettedCenter];
    }
    else if ([self underLeftShowing] && ![self topViewIsOffScreen]) {
        [self updateUnderLeftLayout];
        [self updateTopViewHorizontalCenter:self.anchorRightTopViewCenter];
    }
    else if ([self underLeftShowing] && [self topViewIsOffScreen]) {
        [self updateUnderLeftLayout];
        [self updateTopViewHorizontalCenter:self.screenWidth + self.resettedCenter];
    }
}

- (void)updateTopViewHorizontalCenterWithRecognizer:(UIPanGestureRecognizer*)recognizer {
    CGPoint currentTouchPoint     = [recognizer locationInView:self.view];
    CGFloat currentTouchPositionX = currentTouchPoint.x;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.initialTouchPositionX = currentTouchPositionX;
        self.initialHoizontalCenter = self.topView.center.x;
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.view];

        if (fabs(translation.x) > fabs(translation.y)) {
            CGFloat panAmount = self.initialTouchPositionX - currentTouchPositionX;
            CGFloat newCenterPosition = self.initialHoizontalCenter - panAmount;

            if ((newCenterPosition < self.resettedCenter && self.anchorLeftTopViewCenter == NSNotFound) || (newCenterPosition > self.resettedCenter && self.anchorRightTopViewCenter == NSNotFound)) {
                newCenterPosition = self.resettedCenter;
            }

            [self topViewHorizontalCenterWillChange:newCenterPosition];
            [self updateTopViewHorizontalCenter:newCenterPosition];
            [self topViewHorizontalCenterDidChange:newCenterPosition];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGPoint currentVelocityPoint = [recognizer velocityInView:self.view];
        CGFloat currentVelocityX     = currentVelocityPoint.x;
        CGPoint translation = [recognizer translationInView:self.view];

        if ([self underLeftShowing] && [self slideToAnchorPosition:YES velocity:currentVelocityX translation:translation.x]) {
            [self anchorTopViewTo:ECRight];
        }
        else if ([self underRightShowing] && [self slideToAnchorPosition:NO velocity:currentVelocityX translation:translation.x]) {
            [self anchorTopViewTo:ECLeft];
        }
        else {
            [self resetTopView];
        }
    }
}

- (BOOL)slideToAnchorPosition:(BOOL)isAnchorRight velocity:(CGFloat)velocity translation:(CGFloat)xTranslation {
    // Invert when we check for the anchor on the left
    if (!isAnchorRight) {
        velocity = -velocity;
        xTranslation = -xTranslation;
    }
    // Flick to expand the anchor (right anchor flicked to the left)
    if (velocity < -1000) {
        return NO;
    }
    // 1. Flick to anchor view (full screen flicked to right)
    // 2. Move full screen more than 50% (full screen moved >50% to the right)
    // 3. Move anchor more than 50% (right anchor moved >50% to the left)
    return (velocity > 1000 ||
            (xTranslation > 0 && xTranslation > GET_MAINSCREEN_WIDTH / 2) ||
            (xTranslation < 0 && xTranslation >= -GET_MAINSCREEN_WIDTH / 2 + ANCHOR_RIGHT_PEEK));
}

- (UIPanGestureRecognizer*)panGesture {
    return _panGesture;
}

- (void)anchorTopViewTo:(ECSide)side {
    [self anchorTopViewTo:side animations:nil onComplete:nil];
}

- (void)anchorTopViewTo:(ECSide)side animations:(void (^)(void))animations onComplete:(void (^)(void))complete {
    CGFloat newCenter = self.topView.center.x;

    if (side == ECLeft) {
        newCenter = self.anchorLeftTopViewCenter;
    }
    else if (side == ECRight) {
        newCenter = self.anchorRightTopViewCenter;
    }

    [self topViewHorizontalCenterWillChange:newCenter];

    [UIView animateWithDuration:0.25 animations:^{
        if (animations) {
            animations();
        }
        [self updateTopViewHorizontalCenter:newCenter];
    } completion:^(BOOL finished) {
        if (_resetStrategy & ECPanning) {
            self.panGesture.enabled = YES;
        }
        else {
            self.panGesture.enabled = NO;
        }
        if (complete) {
            complete();
        }
        _topViewIsOffScreen = NO;
        [self addTopViewSnapshot];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *key = (side == ECLeft) ? ECSlidingViewTopDidAnchorLeft : ECSlidingViewTopDidAnchorRight;
            [[NSNotificationCenter defaultCenter] postNotificationName:key object:self userInfo:nil];
        });
    }];
}

- (void)anchorTopViewOffScreenTo:(ECSide)side {
    [self anchorTopViewOffScreenTo:side animations:nil onComplete:nil];
}

- (void)anchorTopViewOffScreenTo:(ECSide)side animations:(void(^)(void))animations onComplete:(void(^)(void))complete {
    CGFloat newCenter = self.topView.center.x;

    if (side == ECLeft) {
        newCenter = -self.resettedCenter;
    }
    else if (side == ECRight) {
        newCenter = self.screenWidth + self.resettedCenter;
    }

    [self topViewHorizontalCenterWillChange:newCenter];

    [UIView animateWithDuration:0.25 animations:^{
        if (animations) {
            animations();
        }
        [self updateTopViewHorizontalCenter:newCenter];
    } completion:^(BOOL finished) {
        if (complete) {
            complete();
        }
        _topViewIsOffScreen = YES;
        [self addTopViewSnapshot];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *key = (side == ECLeft) ? ECSlidingViewTopDidAnchorLeft : ECSlidingViewTopDidAnchorRight;
            [[NSNotificationCenter defaultCenter] postNotificationName:key object:self userInfo:nil];
        });
    }];
}

- (void)resetTopView {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewTopWillReset object:self userInfo:nil];
  });
    [self resetTopViewWithAnimations:nil onComplete:nil];
}

- (void)resetTopViewWithAnimations:(void(^)(void))animations onComplete:(void(^)(void))complete {
    [self topViewHorizontalCenterWillChange:self.resettedCenter];
  
    [UIView animateWithDuration:0.25 animations:^{
        if (animations) {
            animations();
        }
        [self updateTopViewHorizontalCenter:self.resettedCenter];
    } completion:^(BOOL finished) {
        if (complete) {
            complete();
        }
        [self topViewHorizontalCenterDidChange:self.resettedCenter];
    }];
}

- (NSUInteger)autoResizeToFillScreen {
    return (UIViewAutoresizingFlexibleWidth |
            UIViewAutoresizingFlexibleHeight |
            UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleBottomMargin |
            UIViewAutoresizingFlexibleLeftMargin |
            UIViewAutoresizingFlexibleRightMargin);
}

- (UIView*)topView {
    return self.topViewController.view;
}

- (UIView*)underLeftView {
    return self.underLeftViewController.view;
}

- (UIView*)underRightView {
    return self.underRightViewController.view;
}

- (void)updateTopViewHorizontalCenter:(CGFloat)newHorizontalCenter {
    CGPoint center = self.topView.center;
    center.x = newHorizontalCenter;
    self.topView.layer.position = center;
}

- (void)topViewHorizontalCenterWillChange:(CGFloat)newHorizontalCenter {
CGPoint center = self.topView.center;

    if (center.x >= self.resettedCenter && newHorizontalCenter == self.resettedCenter) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewUnderLeftWillDisappear object:self userInfo:nil];
        });
    }

    if (center.x <= self.resettedCenter && newHorizontalCenter == self.resettedCenter) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewUnderRightWillDisappear object:self userInfo:nil];
        });
    }

    if (center.x <= self.resettedCenter && newHorizontalCenter > self.resettedCenter) {
        [self underLeftWillAppear];
    }
    else if (center.x >= self.resettedCenter && newHorizontalCenter < self.resettedCenter) {
        [self underRightWillAppear];
    }
}

- (void)topViewHorizontalCenterDidChange:(CGFloat)newHorizontalCenter {
    if (newHorizontalCenter == self.resettedCenter) {
        [self topDidReset];
    }
}

- (void)addTopViewSnapshot {
    if (!self.topViewSnapshot.superview && !self.shouldAllowUserInteractionsWhenAnchored) {
        topViewSnapshot.frame = self.view.frame;
        if (self.shouldAddPanGestureRecognizerToTopViewSnapshot && (_resetStrategy & ECPanning)) {
            if (!_topViewSnapshotPanGesture) {
                _topViewSnapshotPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateTopViewHorizontalCenterWithRecognizer:)];
            }
            [topViewSnapshot addGestureRecognizer:_topViewSnapshotPanGesture];
        }
        [self.topView addSubview:self.topViewSnapshot];
    }
}

- (void)removeTopViewSnapshot {
    if (self.topViewSnapshot.superview) {
        [self.topViewSnapshot removeFromSuperview];
    }
}

- (CGFloat)anchorRightTopViewCenter {
    if (self.anchorRightPeekAmount) {
        return self.screenWidth + self.resettedCenter - self.anchorRightPeekAmount;
    }
    else if (self.anchorRightRevealAmount) {
        return self.resettedCenter + self.anchorRightRevealAmount;
    }
    else {
        return NSNotFound;
    }
}

- (CGFloat)anchorLeftTopViewCenter {
    if (self.anchorLeftPeekAmount) {
        return -self.resettedCenter + self.anchorLeftPeekAmount;
    }
    else if (self.anchorLeftRevealAmount) {
        return -self.resettedCenter + (self.screenWidth - self.anchorLeftRevealAmount);
    }
    else {
        return NSNotFound;
    }
}

- (CGFloat)resettedCenter {
    return ceil(self.screenWidth / 2);
}

- (CGFloat)screenWidth {
    return [self screenWidthForOrientation:IS_LANDSCAPE];
}

- (CGFloat)screenWidthForOrientation:(BOOL)isLandscape {
    CGSize size = UIScreen.mainScreen.bounds.size;
    UIApplication *application = UIApplication.sharedApplication;
    if (isLandscape) {
        size = CGSizeMake(size.height, size.width);
    }
    if (!application.statusBarHidden) {
        size.height -= MIN(application.statusBarFrame.size.width, application.statusBarFrame.size.height);
    }
    return size.width;
}

- (void)underLeftWillAppear {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewUnderLeftWillAppear object:self userInfo:nil];
    });
    self.underRightView.hidden = YES;
    self.underLeftView.hidden = NO;
    [self updateUnderLeftLayout];
    _underLeftShowing  = YES;
    _underRightShowing = NO;
}

- (void)underRightWillAppear {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewUnderRightWillAppear object:self userInfo:nil];
    });
    self.underLeftView.hidden = YES;
    self.underRightView.hidden = NO;
    [self updateUnderRightLayout];
    _underLeftShowing  = NO;
    _underRightShowing = YES;
}

- (void)topDidReset {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewTopDidReset object:self userInfo:nil];
    });
    [self.topView removeGestureRecognizer:self.resetTapGesture];
    [self removeTopViewSnapshot];
    self.panGesture.enabled = YES;
    _underLeftShowing   = NO;
    _underRightShowing  = NO;
    _topViewIsOffScreen = NO;
}

- (BOOL)topViewHasFocus {
    return !_underLeftShowing && !_underRightShowing && !_topViewIsOffScreen;
}

- (void)updateUnderLeftLayout {
    if (self.underLeftWidthLayout == ECFullWidth) {
        self.underLeftView.autoresizingMask = self.autoResizeToFillScreen;
        self.underLeftView.frame = self.view.bounds;
    }
    else if (self.underLeftWidthLayout == ECVariableRevealWidth && !self.topViewIsOffScreen) {
        CGRect frame = self.view.bounds;
        CGFloat newWidth;

        if (IS_LANDSCAPE) {
            newWidth = UIScreen.mainScreen.bounds.size.height - self.anchorRightPeekAmount;
        }
        else {
            newWidth = UIScreen.mainScreen.bounds.size.width - self.anchorRightPeekAmount;
        }

        frame.size.width = newWidth;

        self.underLeftView.frame = frame;
    }
    else if (self.underLeftWidthLayout == ECFixedRevealWidth) {
        CGRect frame = self.view.bounds;

        frame.size.width = self.anchorRightRevealAmount;
        self.underLeftView.frame = frame;
    }
    else {
        [NSException raise:@"Invalid Width Layout" format:@"underLeftWidthLayout must be a valid ECViewWidthLayout"];
    }
}

- (void)updateUnderRightLayout {
    if (self.underRightWidthLayout == ECFullWidth) {
        self.underRightViewController.view.autoresizingMask = self.autoResizeToFillScreen;
        self.underRightView.frame = self.view.bounds;
    }
    else if (self.underRightWidthLayout == ECVariableRevealWidth) {
        CGRect frame = self.view.bounds;

        CGFloat newLeftEdge;
        CGFloat newWidth;

        if (IS_LANDSCAPE) {
            newWidth = UIScreen.mainScreen.bounds.size.height;
        }
        else {
            newWidth = UIScreen.mainScreen.bounds.size.width;
        }

        if (self.topViewIsOffScreen) {
            newLeftEdge = 0;
        }
        else {
            newLeftEdge = self.anchorLeftPeekAmount;
            newWidth   -= self.anchorLeftPeekAmount;
        }

        frame.origin.x   = newLeftEdge;
        frame.size.width = newWidth;

        self.underRightView.frame = frame;
    }
    else if (self.underRightWidthLayout == ECFixedRevealWidth) {
        CGRect frame = self.view.bounds;

        CGFloat newLeftEdge = self.screenWidth - self.anchorLeftRevealAmount;
        CGFloat newWidth = self.anchorLeftRevealAmount;

        frame.origin.x   = newLeftEdge;
        frame.size.width = newWidth;

        self.underRightView.frame = frame;
    }
    else {
        [NSException raise:@"Invalid Width Layout" format:@"underRightWidthLayout must be a valid ECViewWidthLayout"];
    }
}

@end
