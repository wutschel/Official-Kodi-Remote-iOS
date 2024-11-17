//
//  ConvenienceMacros.h
//  Kodi Remote
//
//  Created by Buschmann on 07.07.21.
//  Copyright © 2021 joethefox inc. All rights reserved.
//

#ifndef ConvenienceMacros_h
#define ConvenienceMacros_h

/*
 * Device and orientation checks
 */
#define IS_IPHONE (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone)
#define IS_IPAD (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define IS_PORTRAIT UIInterfaceOrientationIsPortrait(UIApplication.sharedApplication.statusBarOrientation)
#define IS_LANDSCAPE UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)
 
/*
 * Color defines
 */
#define APP_TINT_COLOR [Utilities getGrayColor:0 alpha:0.3]
#define ICON_TINT_COLOR UIColor.lightGrayColor
#define ICON_TINT_COLOR_ACTIVE UIColor.systemBlueColor
#define BAR_TINT_COLOR [Utilities getGrayColor:26 alpha:1]
#define REMOTE_CONTROL_BAR_TINT_COLOR [Utilities getGrayColor:12 alpha:1]
#define SLIDER_DEFAULT_COLOR UIColor.lightGrayColor
#define TOOLBAR_TINT_COLOR [Utilities getGrayColor:38 alpha:0.95]
#define KODI_BLUE_COLOR [Utilities getKodiBlue]

/*
 * Dimension and layout macros
 */
#define GET_MAINSCREEN_HEIGHT CGRectGetHeight(UIScreen.mainScreen.fixedCoordinateSpace.bounds)
#define GET_MAINSCREEN_WIDTH CGRectGetWidth(UIScreen.mainScreen.fixedCoordinateSpace.bounds)
#define STACKSCROLL_WIDTH (GET_MAINSCREEN_WIDTH - PAD_MENU_TABLE_WIDTH)
#define ANCHOR_RIGHT_PEEK (GET_MAINSCREEN_WIDTH/10.0)
#define IPAD_MENU_SEPARATOR_WIDTH 0.5

/*
 * Other
 */
#define LOCALIZED_STR(string) NSLocalizedString(string, nil)
#define LOCALIZED_STR_ARGS(string, ...) [NSString stringWithFormat:LOCALIZED_STR(string), __VA_ARGS__]
#define SD_NATIVESIZE_KEY @"nativeSize"
#define SD_ASPECTMODE_KEY @"aspectMode"
#define FLOAT_EQUAL_ZERO(x) (fabs(x) < FLT_EPSILON)

/*
 * Font scaling
 */
#define FONT_SCALING_MIN 0.8
#define FONT_SCALING_DEFAULT 0.9
#define FONT_SCALING_NONE 1.0

/*
 * Port defaults
 */
#define DEFAULT_SERVER_PORT 8080
#define DEFAULT_TCP_PORT 9090

#endif /* ConvenienceMacros_h */
