//
//  SequenceViewController.m
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceViewController.h"

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
    // NSArray *items = [[[[[CoreDataManager sharedManager].managedObjectContext ofType:@"Item"] where:@"parentItem == %@  AND isCompleted == NO", parent] orderBy:@"sortingIndex"] toArray];
}

- (void)reloadSequenceFromNotification:(NSNotification *)notification
{
    [self reloadSequence];
}

- (void)reloadSequence
{
    NSLog(@"reload sequence");
}

@end
