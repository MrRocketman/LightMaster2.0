//
//  ControlBoxViewController.h
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SNRFetchedResultsController.h"

@interface ControlBoxViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, SNRFetchedResultsControllerDelegate, NSTextFieldDelegate>

@property (strong, nonatomic) IBOutlet NSButton *createControlBoxButton;
@property (strong, nonatomic) IBOutlet NSTableView *controlBoxTableView;
@property (strong, nonatomic) IBOutlet NSButton *createChannelButton;
@property (strong, nonatomic) IBOutlet NSTableView *channelsTableView;

- (IBAction)createControlBoxButtonPress:(id)sender;
- (IBAction)createChannelButtonPress:(id)sender;
- (IBAction)colorChange:(id)sender;

@end
