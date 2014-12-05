//
//  SequenceListViewController.h
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SNRFetchedResultsController.h"

@interface SequenceListViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, SNRFetchedResultsControllerDelegate>

@property (strong, nonatomic) IBOutlet NSButton *createSequenceButton;
@property (strong, nonatomic) IBOutlet NSButton *loadSequenceButton;
@property (strong, nonatomic) IBOutlet NSTableView *sequenceTableView;

@property (strong, nonatomic) IBOutlet NSButton *createTrackButton;
@property (strong, nonatomic) IBOutlet NSTableView *trackTableView;

@property (strong, nonatomic) IBOutlet NSButton *createTrackChannelButton;
@property (strong, nonatomic) IBOutlet NSTableView *trackChannelTableView;

- (IBAction)createSequenceButtonPress:(id)sender;
- (IBAction)loadSequenceButtonPress:(id)sender;
- (IBAction)createTrackButtonPress:(id)sender;
- (IBAction)createTrackChannelButtonPress:(id)sender;

@end
