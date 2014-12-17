//
//  CoreDataManager.h
//  StopWatch
//
//  Created by James Adams on 9/30/14.
//  Copyright (c) 2014 PBI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Playlist, Sequence, SequenceTatum, ControlBox, Channel, ControlBox, CommandOn, CommandFade, AudioLyric;

@interface CoreDataManager : NSObject

+ (CoreDataManager *)sharedManager;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) Sequence *currentSequence;
@property (assign, nonatomic) float zoomLevel;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

// Playlist
- (Playlist *)newPlaylist;

// Sequence Methods
- (Sequence *)newSequence;
- (void)getLatestOrCreateNewSequence;
- (void)updateSequenceTatumsForNewEndTime:(float)endTime;
- (SequenceTatum *)addSequenceTatumToSequence:(Sequence *)sequence atTime:(float)time;
- (void)updateSequenceTatumsForNewAudioForSequence:(Sequence *)sequence;

// ControlBox Methods
- (ControlBox *)newControlBox;
- (ControlBox *)newAnalysisControlBoxForSequence:(Sequence *)sequence;
- (Channel *)newChannelForControlBox:(ControlBox *)controlBox;

// Command Methods
- (CommandOn *)addCommandOnWithStartTatum:(SequenceTatum *)startTatum endTatum:(SequenceTatum *)endTatum brightness:(float)brightness channel:(Channel *)channel;
- (CommandFade *)addCommandFadeWithStartTatum:(SequenceTatum *)startTatum endTatum:(SequenceTatum *)endTatum startBrightness:(float)startBrightness endBrightness:(float)endBrightness channel:(Channel *)channel;

// Audio
- (AudioLyric *)newAudioLyricForSequence:(Sequence *)sequence;

@end
