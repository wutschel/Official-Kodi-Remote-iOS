//
//  ProgressBarView.m
//  Kodi Remote
//
//  Created by Buschmann on 12.01.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "ProgressBarView.h"
#import "Utilities.h"

#define PROGRESSBAR_RADIUS 2

@implementation ProgressBarView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createProgressBar];
    }
    return self;
}

- (void)createProgressBar {
    progressBarTrack = [UIView new];
    progressBarTrack.layer.cornerRadius = PROGRESSBAR_RADIUS;
    progressBarTrack.clipsToBounds = YES;
    [self addSubview:progressBarTrack];
    
    progressBar = [UIView new];
    progressBar.backgroundColor = KODI_BLUE_COLOR;
    [progressBarTrack addSubview:progressBar];
}

- (void)setTrackColor:(UIColor*)color {
    progressBarTrack.backgroundColor = color;
}

- (void)setProgress:(CGFloat)progress {
    CGRect frame = progressBar.frame;
    frame.size.width = progress * CGRectGetWidth(self.frame);
    progressBar.frame = frame;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.frame;
    progressBarTrack.frame = CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame));
    progressBar.frame = CGRectMake(0, 0, 0, CGRectGetHeight(frame));
}

@end
