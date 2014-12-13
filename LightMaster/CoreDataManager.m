//
//  CoreDataManager.m
//  StopWatch
//
//  Created by James Adams on 9/30/14.
//  Copyright (c) 2014 PBI. All rights reserved.
//

#import "CoreDataManager.h"
#import "NSManagedObjectContext+Queryable.h"
#import "AppDelegate.h"
#import "Sequence.h"
#import "SequenceTatum.h"
#import "ControlBox.h"
#import "Channel.h"
#import "Audio.h"
#import "AudioLyric.h"
#import "EchoNestAudioAnalysis.h"
#import "EchoNestTatum.h"
#import "EchoNestSegment.h"
#import "Command.h"
#import "CommandOn.h"
#import "CommandFade.h"
#import "SequenceLogic.h"

@interface CoreDataManager()

@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (assign, nonatomic) BOOL aSequenceHasBeenLoaded;

@end

@implementation CoreDataManager

+ (CoreDataManager *)sharedManager
{
    static dispatch_once_t once;
    static CoreDataManager *instance;
    dispatch_once(&once, ^
                  {
                      instance = [[CoreDataManager alloc] init];
                  });
    return instance;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [self managedObjectContext]; // Create the managedObjectContext
        
        // Add a default control box and channel
        if([[[self.managedObjectContext ofType:@"ControlBox"] toArray] count] == 0)
        {
            [self newControlBox];
        }
    }
    
    return self;
}

#pragma mark - Core Data stack

- (NSURL *)applicationDocumentsDirectory
{
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.jamesadams.LightMaster" in the user's Application Support directory.
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.jamesadams.LightMaster"];
}

/*- (NSManagedObjectContext *)backgroundThreadManagedObjectContext
{
    dispatch_queue_t request_queue = dispatch_queue_create("com.xxx.ScsMethod", NULL);
    dispatch_async(request_queue, ^{
        NSPersistentStoreCoordinator *mainThreadContextStoreCoordinator = [context     persistentStoreCoordinator]; //
        NSManagedObjectContext *context = [[NSManagedObjectContext alloc] init]; //
        [context setPersistentStoreCoordinator:mainThreadContextStoreCoordinator];}
}*/

- (NSManagedObjectContext *)managedObjectContext
{
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator)
    {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationDocumentsDirectory = [self applicationDocumentsDirectory];
    BOOL shouldFail = NO;
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    // Make sure the application files directory is there
    NSDictionary *properties = [applicationDocumentsDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    if (properties)
    {
        if (![properties[NSURLIsDirectoryKey] boolValue])
        {
            failureReason = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationDocumentsDirectory path]];
            shouldFail = YES;
        }
    }
    else if ([error code] == NSFileReadNoSuchFileError)
    {
        error = nil;
        [fileManager createDirectoryAtPath:[applicationDocumentsDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if (!shouldFail && !error)
    {
        // Create the coordinator and store
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LightMaster.sqlite"];
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES, NSPersistentStoreUbiquitousContentNameKey: @"LightMasterCloudData"};
        NSError *error = nil;
        
        // iCloud persistant store change notification. This needs to happen before we addPersistentStore, else we will never get this.
        [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresWillChangeNotification object:_persistentStoreCoordinator queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
         {
             NSLog(@"PersistantStore will change");
             // Disable UI. No changges allowed until storedidChange
             //self.persistantStoreChangeOverlay = [[UIAlertView alloc] initWithTitle:@"iCloud" message:@"Initializing iCloud Database" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
             //[self.persistantStoreChangeOverlay show];
             
             [self.managedObjectContext performBlock:^
              {
                  if ([self.managedObjectContext hasChanges])
                  {
                      NSError *saveError;
                      if (![self.managedObjectContext save:&saveError])
                      {
                          NSLog(@"Save error: %@", saveError);
                      }
                  }
                  else
                  {
                      // drop any managed object references
                      [self.managedObjectContext reset];
                  }
              }];
         }];
        // iCloud persistant store change notification. This needs to happen before we addPersistentStore, else we will never get this.
        [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreCoordinatorStoresDidChangeNotification object:_persistentStoreCoordinator queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
         {
             NSLog(@"PersistantStore did change");
             // Enable the UI
             //[self.persistantStoreChangeOverlay dismissWithClickedButtonIndex:0 animated:YES];
             // App delegate will pop to root and update everything
         }];
        // iCloud data change notification
        [[NSNotificationCenter defaultCenter] addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:_persistentStoreCoordinator queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note)
         {
             //NSLog(@"iCloud content change");
             [self.managedObjectContext performBlock:^
              {
                  [self.managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                  
                  // This iterates through the changes objects. No need to do it here though
                  /*NSDictionary *changes = note.userInfo;
                   NSMutableSet *allChanges = [NSMutableSet new];
                   [allChanges unionSet:changes[NSInsertedObjectsKey]];
                   [allChanges unionSet:changes[NSUpdatedObjectsKey]];
                   [allChanges unionSet:changes[NSDeletedObjectsKey]];
                   
                   for (NSManagedObjectID *objID in allChanges) {
                   // do whatever you need to with the NSManagedObjectID
                   // you can retrieve the object from with [moc objectWithID:objID]
                   NSLog(@"objID:%@", [self.managedObjectContext objectWithID:objID]);
                   }*/
                  
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"UbiquitousContentChange" object:nil userInfo:note.userInfo];
              }];
         }];
        
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
        {
            // Report any error we got.
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
            dict[NSLocalizedFailureReasonErrorKey] = @"There was an error creating or loading the application's saved data.";;
            dict[NSUnderlyingErrorKey] = error;
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
    }
    
    if (shouldFail || error)
    {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        if (error)
        {
            dict[NSUnderlyingErrorKey] = error;
        }
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectModel *)managedObjectModel
{
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"LightMaster" withExtension:@"momd"]];
    return _managedObjectModel;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    return [[self managedObjectContext] undoManager];
}

#pragma mark - Core Data Saving support

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil)
    {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
    }
}

#pragma mark - Sequence Methods

- (Sequence *)newSequence
{
    Sequence *sequence = [NSEntityDescription insertNewObjectForEntityForName:@"Sequence" inManagedObjectContext:self.managedObjectContext];
    sequence.modifiedDate = [NSDate date];
    sequence.title = @"New Sequence";
    sequence.endTime = @10.0;
    sequence.uuid = [[NSUUID UUID] UUIDString];
    
    // Make the default tatum set
    for(int i = 0; i <= [sequence.endTime floatValue] / 0.1; i ++)
    {
        [self addSequenceTatumToSequence:sequence atTime:i * 0.1];
    }
    
    // Add any control boxes that already exist
    [sequence addControlBoxes:[NSSet setWithArray:[[[self.managedObjectContext ofType:@"ControlBox"] where:@"analysisSequence == nil"] toArray]]];
    
    // Add a default analysisControlBox
    [self newAnalysisControlBoxForSequence:sequence];
    
    // Save
    [self saveContext];
    
    return sequence;
}

- (SequenceTatum *)addSequenceTatumToSequence:(Sequence *)sequence atTime:(float)time
{
    SequenceTatum *tatum = [NSEntityDescription insertNewObjectForEntityForName:@"SequenceTatum" inManagedObjectContext:self.managedObjectContext];
    tatum.time = @(time);
    tatum.uuid = [[NSUUID UUID] UUIDString];
    [sequence addTatumsObject:tatum];
    
    return tatum;
}

- (void)getLatestOrCreateNewSequence
{
    // Get the most recently modifed StopWatch or create the first one
    if(self.currentSequence == nil)
    {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Sequence"];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modifiedDate" ascending:NO]];
        NSError *error;
        NSArray *fetchResults = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        if([fetchResults count] > 0 && !self.aSequenceHasBeenLoaded)
        {
            self.currentSequence = [fetchResults firstObject];
        }
        else
        {
            self.currentSequence = [self newSequence];
        }
    }
    
    self.aSequenceHasBeenLoaded = YES;
}

- (void)updateSequenceTatumsForNewEndTime:(float)newEndTime
{
    // Add tatums
    if(newEndTime > [self.currentSequence.endTime floatValue])
    {
        SequenceTatum *lastTatum = [[[[[self.managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@", self.currentSequence] orderBy:@"time"] toArray] lastObject];
        
        // If we are past the last tatum, add audio data
        if(newEndTime > [lastTatum.time floatValue])
        {
            // If we have audio data , add back in the audio tatums
            if(self.currentSequence.audio.echoNestAudioAnalysis)
            {
                NSArray *echoNestTatums = [[[[self.managedObjectContext ofType:@"EchoNestTatum"] where:@"echoNestAudioAnalysis == %@ AND start > %f AND start <= %f", self.currentSequence.audio.echoNestAudioAnalysis, [lastTatum.time floatValue], newEndTime] orderBy:@"start"] toArray];
                for(EchoNestTatum *echoTatum in echoNestTatums)
                {
                    [self addSequenceTatumToSequence:self.currentSequence atTime:[echoTatum.start floatValue]];
                }
            }
            else if(newEndTime > [lastTatum.time floatValue] + 0.1)
            {
                for(float i = [lastTatum.time floatValue] + 0.1; i <= newEndTime; i += 0.1)
                {
                    [self addSequenceTatumToSequence:self.currentSequence atTime:i];
                }
            }
        }
    }
    // Remove tatums
    else if(newEndTime < [self.currentSequence.endTime floatValue])
    {
        NSSet *tatumsToRemove = [NSSet setWithArray:[[[self.managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@ AND time > %f", self.currentSequence, newEndTime] toArray]];
        [self.currentSequence removeTatums:tatumsToRemove];
    }
    
    // Save
    [self saveContext];
}

- (void)updateSequenceTatumsForNewAudioForSequence:(Sequence *)sequence
{
    // Remove all the old tatums
    NSArray *tatums = [[[self.managedObjectContext ofType:@"SequenceTatum"] where:@"sequence == %@", sequence] toArray];
    for(SequenceTatum *tatum in tatums)
    {
        [self.managedObjectContext deleteObject:tatum];
    }
    
    // Make the new tatums
    NSSet *echoTatums = sequence.audio.echoNestAudioAnalysis.tatums;
    for(EchoNestTatum *echoTatum in echoTatums)
    {
        [self addSequenceTatumToSequence:sequence atTime:[echoTatum.start floatValue]];
    }
    /*NSSet *echoSegments = sequence.audio.echoNestAudioAnalysis.segments;
    for(EchoNestSegment *echoSegment in echoSegments)
    {
        [self addSequenceTatumToSequence:sequence atTime:[echoSegment.start floatValue]];
    }*/
    
    // Save
    [self saveContext];
}

#pragma mark - ControlBox Methods

- (ControlBox *)newControlBox
{
    ControlBox *controlBox = [NSEntityDescription insertNewObjectForEntityForName:@"ControlBox" inManagedObjectContext:[self managedObjectContext]];
    controlBox.title = @"New Box";
    controlBox.uuid = [[NSUUID UUID] UUIDString];
    controlBox.idNumber = @([[[[self.managedObjectContext ofType:@"ControlBox"] where:@"analysisSequence == nil"] toArray] count]);
    
    // Make a default channel
    [self newChannelForControlBox:controlBox];
    
    // Add the new box to all the sequences
    NSArray *sequences = [[self.managedObjectContext ofType:@"Sequence"] toArray];
    for(Sequence *sequence in sequences)
    {
        [sequence addControlBoxesObject:controlBox];
    }
    
    [self saveContext];
    
    return controlBox;
}

- (ControlBox *)newAnalysisControlBoxForSequence:(Sequence *)sequence;
{
    ControlBox *controlBox = [NSEntityDescription insertNewObjectForEntityForName:@"ControlBox" inManagedObjectContext:self.managedObjectContext];
    controlBox.title = @"New Track";
    controlBox.uuid = [[NSUUID UUID] UUIDString];
    controlBox.idNumber = @([[[[self.managedObjectContext ofType:@"ControlBox"] where:@"analysisSequence != nil"] toArray] count]);
    controlBox.analysisSequence = sequence;
    
    // Make a default channel
    [self newChannelForControlBox:controlBox];
    
    [self saveContext];
    
    return controlBox;
}

- (Channel *)newChannelForControlBox:(ControlBox *)controlBox
{
    Channel *channel = [NSEntityDescription insertNewObjectForEntityForName:@"Channel" inManagedObjectContext:[self managedObjectContext]];
    channel.title = @"New Channel";
    channel.idNumber = @(controlBox.channels.count);
    channel.uuid = [[NSUUID UUID] UUIDString];
    channel.color = [NSColor whiteColor];
    [controlBox addChannelsObject:channel];
    
    [self saveContext];
    
    return channel;
}

#pragma mark - Command Methods

- (CommandOn *)addCommandOnWithStartTatum:(SequenceTatum *)startTatum endTatum:(SequenceTatum *)endTatum brightness:(float)brightness channel:(Channel *)channel
{
    CommandOn *command = [NSEntityDescription insertNewObjectForEntityForName:@"CommandOn" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
    command.startTatum = startTatum;
    command.endTatum = endTatum;
    command.brightness = @(brightness);
    command.channel = channel;
    command.uuid = [[NSUUID UUID] UUIDString];
    
    return command;
}

- (CommandFade *)addCommandFadeWithStartTatum:(SequenceTatum *)startTatum endTatum:(SequenceTatum *)endTatum startBrightness:(float)startBrightness endBrightness:(float)endBrightness channel:(Channel *)channel
{
    CommandFade *command = [NSEntityDescription insertNewObjectForEntityForName:@"CommandFade" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
    command.startTatum = startTatum;
    command.endTatum = endTatum;
    command.startBrightness = @(startBrightness);
    command.endBrightness = @(endBrightness);
    command.channel = channel;
    command.uuid = [[NSUUID UUID] UUIDString];
    
    return command;
}

#pragma mark - Audio

- (AudioLyric *)newAudioLyricForSequence:(Sequence *)sequence
{
    AudioLyric *lyric = [NSEntityDescription insertNewObjectForEntityForName:@"AudioLyric" inManagedObjectContext:self.managedObjectContext];
    lyric.text = @"Lyric";
    lyric.time = @(1.0);
    lyric.audio = sequence.audio;
    
    [self saveContext];
    
    return lyric;
}

@end
