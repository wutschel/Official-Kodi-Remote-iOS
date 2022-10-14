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
@property (nonatomic, copy) NSString *label;
@end

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
