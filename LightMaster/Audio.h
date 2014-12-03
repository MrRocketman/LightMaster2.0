//
//  Audio.h
//  LightMaster
//
//  Created by James Adams on 12/2/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EchoNestAudioAnalysis, Sequence;

@interface Audio : NSManagedObject

@property (nonatomic, retain) NSData * audioFile;
@property (nonatomic, retain) NSNumber * echoNestUploadProgress;
@property (nonatomic, retain) NSNumber * endOffset;
@property (nonatomic, retain) NSNumber * startOffset;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) EchoNestAudioAnalysis *echoNestAudioAnalysis;
@property (nonatomic, retain) NSSet *sequence;
@end

@interface Audio (CoreDataGeneratedAccessors)

- (void)addSequenceObject:(Sequence *)value;
- (void)removeSequenceObject:(Sequence *)value;
- (void)addSequence:(NSSet *)values;
- (void)removeSequence:(NSSet *)values;

@end
