//
//  SequenceScrollView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "Sequence.h"
#import "Audio.h"
#import "UserAudioAnalysis.h"

#import "SequenceScrollView.h"
#import "SequenceView.h"
#import "SequenceChannelHeaderView.h"
#import "SequenceChannelView.h"
#import "SequenceUserTatumsView.h"
#import "SequenceTimelineView.h"

@implementation SequenceScrollView

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsChange:) name:NSViewBoundsDidChangeNotification object:self.contentView];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)scrollViewBoundsChange:(NSNotification *)notification
{
    [self.sequenceView scrollViewBoundsChange:notification];
    [self.channelHeaderView scrollViewBoundsChange:notification];
    [self.channelView scrollViewBoundsChange:notification];
    [self.timelineView scrollViewBoundsChange:notification];
    [self.userTatumsView scrollViewBoundsChange:notification];
}

- (void)updateViews
{
    [self.sequenceView setNeedsDisplay:YES];
    [self.channelHeaderView setNeedsDisplay:YES];
    [self.channelView setNeedsDisplay:YES];
    [self.timelineView setNeedsDisplay:YES];
    [self.userTatumsView setNeedsDisplay:YES];
}

/*- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}*/

@end
