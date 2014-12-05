//
//  Command.h
//  LightMaster
//
//  Created by James Adams on 12/5/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Channel, Sequence, SequenceTatum, UserAudioAnalysisTrackChannel;

@interface Command : NSManagedObject

@property (nonatomic, retain) NSNumber * sendComplete;
@property (nonatomic, retain) Channel *channel;
@property (nonatomic, retain) SequenceTatum *endTatum;
@property (nonatomic, retain) Sequence *sequence;
@property (nonatomic, retain) SequenceTatum *startTatum;
@property (nonatomic, retain) UserAudioAnalysisTrackChannel *userAudioAnalysisTrackChannel;

@end
