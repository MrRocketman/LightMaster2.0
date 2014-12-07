//
//  Sequence.m
//  LightMaster
//
//  Created by James Adams on 12/6/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "Sequence.h"
#import "Audio.h"
#import "Command.h"
#import "ControlBox.h"
#import "Playlist.h"
#import "SequenceTatum.h"
#import "UserAudioAnalysisTrack.h"


@implementation Sequence

@dynamic endOffset;
@dynamic endTime;
@dynamic modifiedDate;
@dynamic startOffset;
@dynamic title;
@dynamic audio;
@dynamic commands;
@dynamic controlBoxes;
@dynamic playlists;
@dynamic tatums;
@dynamic userAudioAnalysisTracks;

@end
