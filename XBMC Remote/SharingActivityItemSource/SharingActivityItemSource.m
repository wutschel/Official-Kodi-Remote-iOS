//
//  SharingActivityItemSource.m
//  Kodi Remote
//
//  Created by Andree Buschmann on 13.10.22.
//  Copyright © 2022 Team Kodi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SharingActivityItemSource.h"

@import LinkPresentation;

@interface SharingActivityItemSource ()
@property (nonatomic, copy) NSURL *url;
@end

@implementation SharingActivityItemSource

- (instancetype)initWithUrlString:(NSString*)urlString {
    if (self = [super init]) {
        self.url = [NSURL URLWithString:urlString];
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
    meta.title = nil;
    meta.imageProvider = [[NSItemProvider alloc] initWithObject:[UIImage imageNamed:@"AppIcon.png"]];
    return meta;
}

- (id)copyWithZone:(NSZone*)zone {
    id copy = [[[self class] allocWithZone:zone] init];
    return copy;
}

@end
