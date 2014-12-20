//
//  SequenceView.m
//  LightMaster
//
//  Created by James Adams on 11/30/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceView.h"

@interface SequenceView()

@end

@implementation SequenceView

- (void)awakeFromNib
{
    self.isAudioAnalysisView = NO;
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"SequenceTatumChange" object:nil];
    
    [self setup];
}

- (void)currentTimeChange:(NSNotification *)notification
{
    // don't redraw if this is a time change
    if(!notification.object)
    {
        [self setNeedsDisplay:YES];
    }
}

@end
