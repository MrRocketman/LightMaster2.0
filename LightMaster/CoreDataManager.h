//
//  CoreDataManager.h
//  StopWatch
//
//  Created by James Adams on 9/30/14.
//  Copyright (c) 2014 PBI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Sequence, SequenceTatum, ControlBox, Channel, ControlBox;

@interface CoreDataManager : NSObject

+ (CoreDataManager *)sharedManager;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) Sequence *currentSequence;
@property (assign, nonatomic) float zoomLevel;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

// Sequence Methods
- (Sequence *)newSequence;
- (void)getLatestOrCreateNewSequence;
- (void)updateSequenceTatumsForNewEndTime:(float)endTime;
- (SequenceTatum *)addSequenceTatumToSequence:(Sequence *)sequence atTime:(float)time;

// ControlBox Methods
- (ControlBox *)newControlBox;
- (ControlBox *)newAnalysisControlBoxForSequence:(Sequence *)sequence;
- (Channel *)newChannelForControlBox:(ControlBox *)controlBox;

@end
