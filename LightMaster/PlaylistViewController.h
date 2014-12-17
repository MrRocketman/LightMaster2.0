//
//  PlaylistViewController.h
//  LightMaster
//
//  Created by James Adams on 12/16/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SNRFetchedResultsController.h"

@interface PlaylistViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, SNRFetchedResultsControllerDelegate>

@property (strong, nonatomic) IBOutlet NSButton *createPlaylistButton;
@property (strong, nonatomic) IBOutlet NSButton *playPlaylistButton;
@property (strong, nonatomic) IBOutlet NSButton *addSequenceToPlaylistButton;

@property (strong, nonatomic) IBOutlet NSTableView *playlistTableView;
@property (strong, nonatomic) IBOutlet NSTableView *currentSequencesTableView;
@property (strong, nonatomic) IBOutlet NSTableView *sequenceTableView;

- (IBAction)createPlaylistButtonPress:(id)sender;
- (IBAction)playPlaylistButtonPress:(id)sender;
- (IBAction)addSequenceToPlaylistButtonPress:(id)sender;

@end
