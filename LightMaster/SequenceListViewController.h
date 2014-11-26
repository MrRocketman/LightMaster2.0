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
@property (strong, nonatomic) IBOutlet NSTableView *tableView;

- (IBAction)createSequenceButtonPress:(id)sender;

@end
