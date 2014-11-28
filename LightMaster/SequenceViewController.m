//
//  SequenceViewController.m
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceViewController.h"
#import "CoreDataManager.h"

@interface SequenceViewController ()

@end

@implementation SequenceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSequenceFromNotification:) name:@"CurrentSequenceChange" object:nil];
}

- (void)viewWillAppear
{
    [[CoreDataManager sharedManager] getLatestOrCreateNewSequence];
}

- (void)reloadSequenceFromNotification:(NSNotification *)notification
{
    [self reloadSequence];
}

- (void)reloadSequence
{
    [self.view setNeedsDisplay:YES];
}

@end
