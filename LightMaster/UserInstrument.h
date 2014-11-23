//
//  UserInstrument.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserAudioAnalysis, UserInstrumentNote;

@interface UserInstrument : NSManagedObject

@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) UserAudioAnalysis *audioAnalysis;
@end

@interface UserInstrument (CoreDataGeneratedAccessors)

- (void)addNotesObject:(UserInstrumentNote *)value;
- (void)removeNotesObject:(UserInstrumentNote *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

@end
