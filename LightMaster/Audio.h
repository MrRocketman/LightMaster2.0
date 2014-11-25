//
//  Audio.h
//  LightMaster
//
//  Created by James Adams on 11/24/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestAudioAnalysis, Sequence, UserAudioAnalysis;

@interface Audio : NSManagedObject

@property (nonatomic, retain) NSData * audioFile;
@property (nonatomic, retain) NSNumber * echoNestUploadProgress;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) EchoNestAudioAnalysis *echoNestAudioAnalysis;
@property (nonatomic, retain) NSSet *sequence;
@property (nonatomic, retain) UserAudioAnalysis *userAudioAnalysis;
@end

@interface Audio (CoreDataGeneratedAccessors)

- (void)addSequenceObject:(Sequence *)value;
- (void)removeSequenceObject:(Sequence *)value;
- (void)addSequence:(NSSet *)values;
- (void)removeSequence:(NSSet *)values;

@end
