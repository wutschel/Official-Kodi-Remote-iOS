//
//  BroadcastProgressView.m
//  Kodi Remote
//
//  Created by Buschmann on 27.12.24.
//  Copyright © 2024 Team Kodi. All rights reserved.
//

#import "BroadcastProgressView.h"
#import "Utilities.h"

#define RESERVED_WIDTH 14
#define PROGRESSBAR_HEIGHT 8
#define FONT_SIZE 10

@implementation BroadcastProgressView

@synthesize barLabel;
@synthesize reservedArea;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createProgressView];
    }
    return self;
}

- (void)createProgressView {
    progressBarView = [ProgressBarView new];
    [self addSubview:progressBarView];
    
    reservedArea = [UILabel new];
    [self addSubview:reservedArea];
    
    barLabel = [UILabel new];
    barLabel.font = [UIFont systemFontOfSize:FONT_SIZE];
    barLabel.adjustsFontSizeToFitWidth = YES;
    barLabel.minimumScaleFactor = FONT_SCALING_MIN;
    barLabel.textAlignment = NSTextAlignmentRight;
    barLabel.textColor = [Utilities get1stLabelColor];
    [self addSubview:barLabel];
}

- (void)setProgress:(CGFloat)progress {
    [progressBarView setProgress:progress];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.frame;
    CGFloat labelHeight = CGRectGetHeight(frame) - PROGRESSBAR_HEIGHT;
    CGFloat labelWidth = CGRectGetWidth(frame) - RESERVED_WIDTH;
    barLabel.frame = CGRectMake(RESERVED_WIDTH, PROGRESSBAR_HEIGHT, labelWidth, labelHeight);
    reservedArea.frame = CGRectMake(0, PROGRESSBAR_HEIGHT, RESERVED_WIDTH, labelHeight);
    progressBarView.frame = CGRectMake(0, 0, CGRectGetWidth(frame), PROGRESSBAR_HEIGHT);
}

@end
