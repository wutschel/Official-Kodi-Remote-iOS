//
//  BroadcastProgressView.h
//  Kodi Remote
//
//  Created by Buschmann on 27.12.24.
//  Copyright © 2024 Team Kodi. All rights reserved.
//

@import UIKit;

@interface BroadcastProgressView : UIView {
    UIView *progressBarMask;
    UIView *progressBar;
}

- (void)setProgressBarPercentage:(CGFloat)progressPercentage;

@property (nonatomic, readonly) UILabel *barLabel;
@property (nonatomic, readonly) UIView *reservedArea;

@end
