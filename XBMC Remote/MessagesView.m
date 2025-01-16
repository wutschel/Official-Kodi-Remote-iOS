//
//  MessagesView.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 8/4/14.
//  Copyright (c) 2014 joethefox inc. All rights reserved.
//

#import "MessagesView.h"
#import "AppDelegate.h"
#import "Utilities.h"

@implementation MessagesView

@synthesize viewMessage;

- (id)initWithFrame:(CGRect)frame deltaY:(CGFloat)deltaY deltaX:(CGFloat)deltaX {
    self = [super initWithFrame:frame];
    if (self) {
        viewMessage = [UILabel new];
        viewMessage.backgroundColor = UIColor.clearColor;
        viewMessage.font = [UIFont boldSystemFontOfSize:16];
        viewMessage.adjustsFontSizeToFitWidth = YES;
        viewMessage.minimumScaleFactor = FONT_SCALING_MIN;
        viewMessage.textColor = UIColor.whiteColor;
        viewMessage.textAlignment = NSTextAlignmentCenter;
        viewMessage.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self updateWithFrame:frame deltaY:deltaY deltaX:deltaX];
        [self addSubview:viewMessage];
        self.alpha = 0.0;
    }
    return self;
}

- (void)updateWithFrame:(CGRect)frame deltaY:(CGFloat)deltaY deltaX:(CGFloat)deltaX {
    messageOrigin = frame.origin.y;
    slideHeight = frame.size.height;
    if (IS_IPAD) {
        slideHeight += [Utilities getTopPadding];
    }
    self.frame = CGRectMake(frame.origin.x, messageOrigin - slideHeight, frame.size.width, frame.size.height);
    viewMessage.frame = CGRectMake(deltaX, deltaY, frame.size.width - deltaX, frame.size.height - deltaY);
}

# pragma mark - view Effects

- (void)showMessage:(NSString*)message timeout:(NSTimeInterval)timeout color:(UIColor*)color {
    // first slide out
    CGRect frame = self.frame;
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.frame = CGRectMake(frame.origin.x, messageOrigin - slideHeight, frame.size.width, frame.size.height);
        self.alpha = 0.0;
                     }
                     completion:nil];
    viewMessage.text = message;
    self.backgroundColor = color;
    // then slide in
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.frame = CGRectMake(frame.origin.x, messageOrigin, frame.size.width, frame.size.height);
        self.alpha = 1.0;
                     }
                     completion:nil];
    // then slide out again after timeout seconds
    // Add timer to RunLoopCommonModes to decouple the timer from touch events like dragging
    [fadeoutTimer invalidate];
    fadeoutTimer = [NSTimer timerWithTimeInterval:timeout target:self selector:@selector(fadeoutMessage:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:fadeoutTimer forMode:NSRunLoopCommonModes];
}

- (void)fadeoutMessage:(NSTimer*)timer {
    CGRect frame = self.frame;
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.frame = CGRectMake(frame.origin.x, messageOrigin - slideHeight, frame.size.width, frame.size.height);
        self.alpha = 0.0;
                     }
                     completion:nil];
    [fadeoutTimer invalidate];
}

@end
