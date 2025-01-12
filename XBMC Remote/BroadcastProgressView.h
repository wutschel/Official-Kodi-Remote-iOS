//
//  BroadcastProgressView.h
//  Kodi Remote
//
//  Created by Buschmann on 27.12.24.
//  Copyright © 2024 Team Kodi. All rights reserved.
//

#import "ProgressBarView.h"
@import UIKit;

@interface BroadcastProgressView : UIView {
    ProgressBarView *progressBarView;
}

- (void)setProgress:(CGFloat)progress;

@property (nonatomic, readonly) UILabel *barLabel;
@property (nonatomic, readonly) UIView *reservedArea;

@end
