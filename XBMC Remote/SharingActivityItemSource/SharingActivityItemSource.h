//
//  SharingActivityItemSource.h
//  Kodi Remote
//
//  Created by Andree Buschmann on 13.10.22.
//  Copyright © 2022 Team Kodi. All rights reserved.
//

@interface SharingActivityItemSource : NSObject <UIActivityItemSource>

- (instancetype)initWithUrlString:(NSString*)urlString label:(NSString*)label image:(UIImage*)image;

@end
