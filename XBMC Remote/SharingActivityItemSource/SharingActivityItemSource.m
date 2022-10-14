//
//  SharingActivityItemSource.m
//  Kodi Remote
//
//  Created by Buschmann on 09.03.25.
//  Copyright © 2025 Team Kodi. All rights reserved.
//

#import "SharingActivityItemSource.h"

@import UIKit;
@import LinkPresentation;

@implementation SharingActivityItemSource

- (instancetype)initWithUrlString:(NSString*)urlString label:(NSString*)label {
    if (self = [super init]) {
        self.url = [NSURL URLWithString:urlString];
        self.label = label;
    }
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController*)activityViewController {
    return self.url;
}

- (id)activityViewController:(UIActivityViewController*)activityViewController itemForActivityType:(NSString*)activityType {
    return self.url;
}

- (LPLinkMetadata*)activityViewControllerLinkMetadata:(UIActivityViewController*)activityViewController API_AVAILABLE(ios(13.0)) {
    __auto_type meta = [LPLinkMetadata new];
    meta.originalURL = self.url;
    meta.URL = meta.originalURL;
    meta.title = self.label;
    meta.imageProvider = [[NSItemProvider alloc] initWithObject:[UIImage imageNamed:@"AppIcon.png"]];
    return meta;
}

- (id)copyWithZone:(NSZone*)zone {
    id copy = [[[self class] allocWithZone:zone] init];
    return copy;
}

@end
