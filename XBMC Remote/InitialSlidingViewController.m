//
//  InitialSlidingViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 7/11/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "InitialSlidingViewController.h"
#import "HostManagementViewController.h"
#import "AppDelegate.h"
#import "Utilities.h"

@interface InitialSlidingViewController ()

@end

@implementation InitialSlidingViewController

@synthesize mainMenu;

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MasterViewController *masterViewController = [[MasterViewController alloc] initWithNibName:@"MasterViewController" bundle:nil];
    masterViewController.mainMenu = self.mainMenu;
    self.underLeftViewController = masterViewController;
    
    HostManagementViewController *hostManagementViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil];
    CustomNavigationController *navController = [[CustomNavigationController alloc] initWithRootViewController:hostManagementViewController];
    navController.navigationBar.barStyle = UIBarStyleBlack;
    navController.navigationBar.tintColor = ICON_TINT_COLOR;
    [Utilities addShadowsToView:navController.view viewFrame:self.view.frame];
    
    self.view.tintColor = APP_TINT_COLOR;
    [navController hideNavBarBottomLine:YES];
    hostManagementViewController.mainMenu = self.mainMenu;
    self.topViewController = navController;
    
    self.slidingViewController.underRightViewController = nil;
    self.slidingViewController.anchorLeftPeekAmount   = 0;
    self.slidingViewController.anchorLeftRevealAmount = 0;
    
    // Hide the inital HostManagementVC in case the "start view" is not main menu to avoid disturbing
    // sliding out (this view) and in (the targeted view).
    self.topViewController.view.hidden = [Utilities getIndexPathForDefaultController:self.mainMenu] != nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleTcpJSONRPCShowSetup:)
                                                 name:@"TcpJSONRPCShowSetup"
                                               object:nil];
}

- (void)handleTcpJSONRPCShowSetup:(NSNotification*)sender {
    // If showSetup is requested, unhide this view in any case. This ensures this view is brought up
    // in case of problems connecting to a server in combination with entering a different "start view".
    BOOL showValue = [[sender.userInfo objectForKey:@"showSetup"] boolValue];
    if (showValue) {
        self.topViewController.view.hidden = NO;
    }
}

- (void)handleMenuButton {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RevealMenu" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
