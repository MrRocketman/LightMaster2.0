//
//  Command.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Channel, Sequence, UserAudioAnalysisTrackChannel;

@interface Command : NSManagedObject

@property (nonatomic, retain) NSNumber * endTime;
@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) Channel *channel;
@property (nonatomic, retain) Sequence *sequence;
@property (nonatomic, retain) UserAudioAnalysisTrackChannel *userAudioAnalysisTrackChannel;

@end
