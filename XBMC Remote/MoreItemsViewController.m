//
//  MoreItemsViewController.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 23/3/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "MoreItemsViewController.h"
#import "AppDelegate.h"
#import "Utilities.h"

@implementation MoreItemsViewController

@synthesize tableView = _tableView;
#define LABEL_PADDING 8
#define INDICATOR_SIZE 16
#define LABEL_OFFSET 50
#define ICON_WIDTH 34
#define ICON_HEIGHT 30

- (id)initWithFrame:(CGRect)frame mainMenu:(NSArray*)menu {
    if (self = [super init]) {
		self.view.frame = frame;
		_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
		_tableView.delegate = self;
		_tableView.dataSource = self;
        _tableView.backgroundColor = UIColor.clearColor;
        mainMenuItems = menu;
        _tableView.separatorInset = UIEdgeInsetsMake(0, LABEL_OFFSET, 0, 0);
        [self.view addSubview:_tableView];
	}
    return self;
}
#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return mainMenuItems.count;
}

- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath {
	cell.backgroundColor = [Utilities getSystemGray6];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
    static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
	}
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    UILabel *cellLabel = [[UILabel alloc] initWithFrame:CGRectMake(LABEL_OFFSET,
                                                                   0,
                                                                   self.view.bounds.size.width - LABEL_OFFSET - INDICATOR_SIZE - 2 * LABEL_PADDING,
                                                                   cell.frame.size.height)];
    cellLabel.font = [UIFont systemFontOfSize:18];
    cellLabel.textColor = [Utilities get1stLabelColor];
    cellLabel.highlightedTextColor = [Utilities get1stLabelColor];
    cellLabel.adjustsFontSizeToFitWidth = YES;
    cellLabel.minimumScaleFactor = FONT_SCALING_MIN;
    NSDictionary *item = mainMenuItems[indexPath.row];
    cellLabel.text = item[@"label"];
    [cell.contentView addSubview:cellLabel];
    if (![item[@"icon"] isEqualToString:@""]) {
        CGRect iconImageViewRect = CGRectMake((LABEL_OFFSET - ICON_WIDTH) / 2, 
                                              (cell.frame.size.height - ICON_HEIGHT) / 2,
                                              ICON_WIDTH,
                                              ICON_HEIGHT);
        UIImageView *iconImage = [[UIImageView alloc] initWithFrame:iconImageViewRect];
        UIImage *image = [Utilities setLightDarkModeImageAsset:[UIImage imageNamed:item[@"icon"]]
                                                    lightColor:UIColor.darkGrayColor
                                                     darkColor:UIColor.lightGrayColor];
        iconImage.image = image;
        [cell.contentView addSubview:iconImage];
    }
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
    [[NSNotificationCenter defaultCenter] postNotificationName: @"tabHasChanged" object: indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - LifeCycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
