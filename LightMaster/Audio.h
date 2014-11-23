//
//  Audio.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestAudioAnalysis, Sequence;

@interface Audio : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * uploadProgress;
@property (nonatomic, retain) NSData * audioFile;
@property (nonatomic, retain) EchoNestAudioAnalysis *echoNestAudioAnalysis;
@property (nonatomic, retain) NSSet *sequence;
@end

@interface Audio (CoreDataGeneratedAccessors)

- (void)addSequenceObject:(Sequence *)value;
- (void)removeSequenceObject:(Sequence *)value;
- (void)addSequence:(NSSet *)values;
- (void)removeSequence:(NSSet *)values;

@end
