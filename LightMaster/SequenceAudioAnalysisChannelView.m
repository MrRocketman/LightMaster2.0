//
//  SequenceAudioAnalysisTracksView.m
//  LightMaster
//
//  Created by James Adams on 12/4/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceAudioAnalysisChannelView.h"
#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "ControlBox.h"
#import "Channel.h"
#import "SequenceLogic.h"

@implementation SequenceAudioAnalysisChannelView

- (void)awakeFromNib
{
    self.isAudioAnalysisView = YES;
    
    [self setup];
}

@end
