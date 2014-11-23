//
//  UserAudioAnalysis.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserInstrument;

@interface UserAudioAnalysis : NSManagedObject

@property (nonatomic, retain) NSSet *instruments;
@end

@interface UserAudioAnalysis (CoreDataGeneratedAccessors)

- (void)addInstrumentsObject:(UserInstrument *)value;
- (void)removeInstrumentsObject:(UserInstrument *)value;
- (void)addInstruments:(NSSet *)values;
- (void)removeInstruments:(NSSet *)values;

@end
