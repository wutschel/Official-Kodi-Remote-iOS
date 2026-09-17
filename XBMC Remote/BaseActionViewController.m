//
//  BaseActionViewController.m
//  Kodi Remote
//
//  Created by Buschmann on 25.12.24.
//  Copyright © 2024 Team Kodi. All rights reserved.
//

#import "BaseActionViewController.h"
#import "AppDelegate.h"
#import "Utilities.h"
#import "RemoteController.h"
#import "NowPlaying.h"

@implementation BaseActionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    xbmcDateFormatter = [NSDateFormatter new];
    xbmcDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    xbmcDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"]; // all times in Kodi PVR are UTC
    xbmcDateFormatter.locale = [NSLocale systemLocale]; // Needed to work with 12h system setting in combination with "UTC"
}

- (void)disableScrollsToTopPropertyOnAllSubviewsOf:(UIView*)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIScrollView class]]) {
            ((UIScrollView*)subview).scrollsToTop = NO;
        }
        [self disableScrollsToTopPropertyOnAllSubviewsOf:subview];
    }
}

- (void)showRemote {
    RemoteController *remote = [[RemoteController alloc] initWithNibName:@"RemoteController" bundle:nil];
    [self.navigationController pushViewController:remote animated:YES];
}

- (void)showNowPlaying {
    NowPlaying *nowPlaying = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    nowPlaying.detailItem = self.detailItem;
    [self.navigationController pushViewController:nowPlaying animated:YES];
}

- (void)simpleAction:(NSString*)action params:(NSDictionary*)params success:(NSString*)successMessage failure:(NSString*)failureMessage {
    [[Utilities getJsonRPC] callMethod:action withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil) {
            [Utilities showMessage:successMessage color:SUCCESS_MESSAGE_COLOR];
        }
        else {
            [Utilities showMessage:failureMessage color:ERROR_MESSAGE_COLOR];
        }
    }];
}

- (void)playerAction:(NSString*)action params:(NSDictionary*)params playerid:(int)playerid {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    mutableParams[@"playerid"] = @(playerid);
    [[Utilities getJsonRPC] callMethod:action withParameters:mutableParams];
}

- (void)playerAction:(NSString*)action params:(NSDictionary*)params {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:@{} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSArray class]]) {
            if ([methodResult count] > 0) {
                int playerID = [Utilities getActivePlayerID:methodResult];
                [self playerAction:action params:params playerid:playerID];
            }
        }
    }];
}

- (void)processFoundPlaylists:(NSMutableArray*)nonemptyPlaylists {
    switch (nonemptyPlaylists.count) {
        // More than one playlist is non-empty. Present an action sheet to let the user select the playlist to play.
        case 3:
        case 2:
        {
            UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:LOCALIZED_STR(@"Select Playlist") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *action_cancel = [UIAlertAction actionWithTitle:LOCALIZED_STR(@"Cancel") style:UIAlertActionStyleCancel handler:nil];
            
            NSArray *actionTitles = @[
                LOCALIZED_STR(@"Music"),
                LOCALIZED_STR(@"Videos"),
                LOCALIZED_STR(@"Pictures"),
            ];
            for (id item in nonemptyPlaylists) {
                int playlistId = [item intValue];
                UIAlertAction *action = [UIAlertAction actionWithTitle:actionTitles[playlistId] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[Utilities getJsonRPC]
                     callMethod:@"Player.Open"
                     withParameters:@{@"item": @{@"position": @(0), @"playlistid": @(playlistId)}}];
                }];
                [alertCtrl addAction:action];
            }
            [alertCtrl addAction:action_cancel];
            alertCtrl.modalPresentationStyle = UIModalPresentationPopover;
            
            UIPopoverPresentationController *popPresenter = [alertCtrl popoverPresentationController];
            if (popPresenter != nil) {
                popPresenter.sourceView = self.view;
                popPresenter.sourceRect = self.view.bounds;
            }
            [self presentViewController:alertCtrl animated:YES completion:nil];
            break;
        }
            
        // Only one playlist was not empty, play the first item of it.
        case 1:
        {
            int playlistId = [nonemptyPlaylists[0] intValue];
            [[Utilities getJsonRPC]
             callMethod:@"Player.Open"
             withParameters:@{@"item": @{@"position": @(0), @"playlistid": @(playlistId)}}];
            break;
        }
        
        // All playlists were empty. Do nothing.
        case 0:
        default:
            break;
    }
}

- (void)recursiveCheckPlaylistArray:(NSArray*)playlistIds index:(int)index foundPlaylists:(NSMutableArray*)nonemptyPlaylists {
    int playlistId = [playlistIds[index] intValue];
    [[Utilities getJsonRPC] callMethod:@"Playlist.GetItems"
                        withParameters:@{@"properties": @[@"title"],
                                         @"playlistid": @(playlistId)}
                          onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSDictionary class]]) {
            NSArray *playlistItems = methodResult[@"items"];
            if ([playlistItems isKindOfClass:[NSArray class]] && [playlistItems count] > 0) {
                [nonemptyPlaylists addObject:playlistIds[index]];
            }
            if (index + 1 < playlistIds.count) {
                // Check next playlist
                [self recursiveCheckPlaylistArray:playlistIds
                                            index:index + 1
                                   foundPlaylists:nonemptyPlaylists];
            }
            else {
                // Checked last playlist, now process the results.
                [self processFoundPlaylists:nonemptyPlaylists];
            }
        }
    }];
}

- (void)playerPlayPause {
    [[Utilities getJsonRPC] callMethod:@"Player.GetActivePlayers" withParameters:@{} onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        if (error == nil && methodError == nil && [methodResult isKindOfClass:[NSArray class]]) {
            if ([methodResult count] > 0) {
                // There is a player active, just address play/pause
                int playerID = [Utilities getActivePlayerID:methodResult];
                [self playerAction:@"Player.PlayPause" params:nil playerid:playerID];
            }
            else {
                // There is no player active. Iterate through all playlists and either play show options to user.
                NSArray *playlistIds = @[
                    @(PLAYERID_MUSIC),
                    @(PLAYERID_VIDEO),
                    @(PLAYERID_PICTURES),
                ];
                NSMutableArray *nonemptyPlaylists = [NSMutableArray new];
                [self recursiveCheckPlaylistArray:playlistIds
                                            index:0
                                   foundPlaylists:nonemptyPlaylists];
            }
        }
    }];
}

- (void)playerOpen:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Player.Open" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
            [self showNowPlaying];
            [Utilities checkForReviewRequest];
        }
    }];
}

- (void)playlistAdd:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Playlist.Add" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
        }
    }];
}

- (void)playlistInsert:(NSDictionary*)params indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    [[Utilities getJsonRPC] callMethod:@"Playlist.Insert" withParameters:params onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"XBMCPlaylistHasChanged" object:nil];
        }
    }];
}

- (void)playlistQueue:(int)playlistid items:(NSDictionary*)playlistItems afterCurrent:(BOOL)afterCurrent indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    NSDictionary *playlistParams = @{
        @"playlistid": @(playlistid),
        @"item": playlistItems,
    };
    if (afterCurrent) {
        NSDictionary *params = @{
            @"playerid": @(playlistid),
            @"properties": @[@"percentage", @"time", @"totaltime", @"partymode", @"position"],
        };
        [[Utilities getJsonRPC]
         callMethod:@"Player.GetProperties"
         withParameters:params
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
            if (error == nil && methodError == nil) {
                if ([methodResult isKindOfClass:[NSDictionary class]]) {
                    if ([methodResult count]) {
                        int newPos = [methodResult[@"position"] intValue] + 1;
                        NSDictionary *params2 = @{
                            @"playlistid": @(playlistid),
                            @"item": playlistItems,
                            @"position": @(newPos),
                        };
                        [self playlistInsert:params2 indicator:cellActivityIndicator];
                    }
                    else {
                        [self playlistAdd:playlistParams indicator:cellActivityIndicator];
                    }
                }
                else {
                    [self playlistAdd:playlistParams indicator:cellActivityIndicator];
                }
            }
            else {
                [self playlistAdd:playlistParams indicator:cellActivityIndicator];
            }
        }];
    }
    else {
        [self playlistAdd:playlistParams indicator:cellActivityIndicator];
    }
}

- (void)startPlaybackItems:(NSDictionary*)playbackItems using:(NSString*)playername shuffle:(BOOL)shuffled resume:(BOOL)resume indicator:(UIActivityIndicatorView*)cellActivityIndicator {
    [cellActivityIndicator startAnimating];
    NSString *optionsKey = @"options";
    NSDictionary *optionsValue = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @(resume), @"resume",
                                  @(shuffled), @"shuffled",
                                  playername, @"playername",
                                  nil];
    NSDictionary *playbackParams = [NSDictionary dictionaryWithObjectsAndKeys:
                                    playbackItems, @"item",
                                    optionsValue, optionsKey,
                                    nil];
    if (shuffled) {
        [[Utilities getJsonRPC]
         callMethod:@"Player.SetPartymode"
         withParameters:@{@"playerid": @0, @"partymode": @NO}
         onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
            [self playerOpen:playbackParams indicator:cellActivityIndicator];
        }];
    }
    else {
        [self playerOpen:playbackParams indicator:cellActivityIndicator];
    }
}

- (void)openURL:(NSString*)url {
    NSURL *nsurl = [NSURL URLWithString:url];
    SFSafariViewController *svc = nil;
    // Try to load the URL via SFSafariViewController. If this is not possible, check if this is loadable
    // with other system applications. If so, load it. If not, show an error popup.
    @try {
        svc = [[SFSafariViewController alloc] initWithURL:nsurl];
    } @catch (NSException *exception) {
        if ([UIApplication.sharedApplication canOpenURL:nsurl]) {
            [UIApplication.sharedApplication openURL:nsurl options:@{} completionHandler:nil];
        }
        else {
            UIAlertController *alertView = [Utilities createAlertOK:LOCALIZED_STR(@"Error loading page") message:exception.reason];
            [self presentViewController:alertView animated:YES completion:nil];
        }
        return;
    }
    UIViewController *ctrl = self;
    svc.delegate = self;
    if (IS_IPAD) {
        // On iPad presenting from the active ViewController results in blank screen
        ctrl = UIApplication.sharedApplication.keyWindow.rootViewController;
    }
    if (![svc isBeingPresented]) {
        if (ctrl.presentedViewController) {
            [ctrl dismissViewControllerAnimated:YES completion:nil];
        }
        [ctrl presentViewController:svc animated:YES completion:nil];
    }
}

- (void)recordChannel:(NSDictionary*)item indicator:(UIActivityIndicatorView*)cellActivityIndicator onSuccess:(void (^)(void))onSuccess {
    NSString *methodToCall = @"PVR.Record";
    NSString *parameterName = @"channel";
    NSNumber *itemid = [Utilities getNumberFromItem:item[@"channelid"]];
    NSNumber *storeChannelid = itemid;
    NSNumber *storeBroadcastid = [Utilities getNumberFromItem:item[@"broadcastid"]];
    if ([itemid longValue] == 0) {
        itemid = [Utilities getNumberFromItem:item[@"pvrExtraInfo"][@"channelid"]];
        if ([itemid longValue] == 0) {
            return;
        }
        storeChannelid = itemid;
        NSDate *starttime = [xbmcDateFormatter dateFromString:item[@"starttime"]];
        NSDate *endtime = [xbmcDateFormatter dateFromString:item[@"endtime"]];
        float percent_elapsed = [Utilities getPercentElapsed:starttime EndDate:endtime];
        if (percent_elapsed < 0) {
            itemid = [Utilities getNumberFromItem:item[@"broadcastid"]];
            storeBroadcastid = itemid;
            storeChannelid = @(0);
            methodToCall = @"PVR.ToggleTimer";
            parameterName = @"broadcastid";
        }
    }
    
    [cellActivityIndicator startAnimating];
    NSDictionary *parameters = @{parameterName: itemid};
    [[Utilities getJsonRPC] callMethod:methodToCall
                        withParameters:parameters
                          onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *error) {
        [cellActivityIndicator stopAnimating];
        if (error == nil && methodError == nil) {
            NSNumber *status = @(![item[@"isrecording"] boolValue]);
            if ([item[@"broadcastid"] longLongValue] > 0) {
                status = @(![item[@"hastimer"] boolValue]);
            }
            NSDictionary *params = @{
                @"channelid": storeChannelid,
                @"broadcastid": storeBroadcastid,
                @"status": status,
            };
            [[NSNotificationCenter defaultCenter] postNotificationName:@"KodiServerRecordTimerStatusChange" object:nil userInfo:params];
            
            if (onSuccess) {
                onSuccess();
            }
        }
        else {
            NSString *message = [Utilities formatClipboardMessage:methodToCall
                                                       parameters:parameters
                                                            error:error
                                                      methodError:methodError];
            UIAlertController *alertCtrl = [Utilities createAlertCopyClipboard:LOCALIZED_STR(@"ERROR") message:message];
            [self presentViewController:alertCtrl animated:YES completion:nil];
        }
    }];
}

@end
