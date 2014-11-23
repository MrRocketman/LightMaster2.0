//
//  Sequence.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Audio, ControlBox;

@interface Sequence : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * startOffset;
@property (nonatomic, retain) NSNumber * endOffset;
@property (nonatomic, retain) NSSet *controlBoxes;
@property (nonatomic, retain) NSSet *audio;
@end

@interface Sequence (CoreDataGeneratedAccessors)

- (void)addControlBoxesObject:(ControlBox *)value;
- (void)removeControlBoxesObject:(ControlBox *)value;
- (void)addControlBoxes:(NSSet *)values;
- (void)removeControlBoxes:(NSSet *)values;

- (void)addAudioObject:(Audio *)value;
- (void)removeAudioObject:(Audio *)value;
- (void)addAudio:(NSSet *)values;
- (void)removeAudio:(NSSet *)values;

@end
