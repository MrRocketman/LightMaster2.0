//
//  SequenceTatums.h
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sequence;

@interface SequenceTatums : NSManagedObject

@property (nonatomic, retain) NSNumber * startTime;
@property (nonatomic, retain) Sequence *sequence;

@end
