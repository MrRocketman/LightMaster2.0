//
//  UserInstrumentNote.h
//  LightMaster
//
//  Created by James Adams on 11/23/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserInstrument;

@interface UserInstrumentNote : NSManagedObject

@property (nonatomic, retain) NSNumber * start;
@property (nonatomic, retain) NSNumber * pitch;
@property (nonatomic, retain) NSNumber * loudness;
@property (nonatomic, retain) NSNumber * swell;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) UserInstrument *instrument;

@end
