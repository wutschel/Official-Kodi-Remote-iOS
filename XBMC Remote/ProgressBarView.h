//
//  ProgressBarView.h
//  Kodi Remote
//
//  Created by Buschmann on 12.01.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

@import UIKit;

@interface ProgressBarView : UIView {
    UIView *progressBarTrack;
    UIView *progressBar;
}

- (void)setTrackColor:(UIColor*)color;
- (void)setProgress:(CGFloat)progress;

@end
