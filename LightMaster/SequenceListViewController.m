//
//  SequenceListViewController.m
//  LightMaster
//
//  Created by James Adams on 11/25/14.
//  Copyright (c) 2014 JamesAdams. All rights reserved.
//

#import "SequenceListViewController.h"
#import "CoreDataManager.h"
#import "Sequence.h"
#import "Audio.h"
#import "AudioLyric.h"
#import "ENAPIRequest.h"
#import "ENAPI.h"
#import "EchoNestAudioAnalysis.h"
#import "EchoNestSection.h"
#import "EchoNestBar.h"
#import "EchoNestBeat.h"
#import "EchoNestTatum.h"
#import "EchoNestSegment.h"
#import "EchoNestTimbre.h"
#import "EchoNestPitch.h"
#import "ControlBox.h"
#import "Channel.h"
#import "ChannelColorTableCellView.h"

@interface SequenceListViewController ()

@property (strong, nonatomic) SNRFetchedResultsController *sequenceFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *trackFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *trackChannelFetchedResultsController;
@property (strong, nonatomic) SNRFetchedResultsController *audioLyricFetchedResultsController;

@property (strong, nonatomic) NSOpenPanel *openPanel;
@property (strong, nonatomic) Audio *currentAudio;

@end

@implementation SequenceListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(echoNestUploadUpdate:) name:@"ENAPIRequest.didSendBodyData" object:nil];
    
    // Sequences
    NSError *error;
    if (![[self sequenceFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
    
    // Tracks
    error = nil;
    if (![[self trackFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
    
    // Track Channels
    error = nil;
    if (![[self trackChannelFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
    
    // Track Channels
    error = nil;
    if (![[self audioLyricFetchedResultsController] performFetch:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (void)viewWillAppear
{
    [self.sequenceTableView reloadData];
    [self.trackTableView reloadData];
    [self.trackChannelTableView reloadData];
    [self.lyricTableView reloadData];
    
    [self updateAudioTitleLabelForSequenceAtRow:(int)self.sequenceTableView.selectedRow];
    [self updateAudioAnlysisProgressLabel];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)updateAudioTitleLabelForSequenceAtRow:(int)row
{
    Sequence *sequence = [self.sequenceFetchedResultsController objectAtIndex:row];
    self.currentAudio = sequence.audio;
    if(sequence.audio.title.length > 0)
    {
        self.audioDescriptionTextField.stringValue = sequence.audio.title;
    }
    else
    {
        self.audioDescriptionTextField.stringValue = @"";
    }
}

- (void)keyDown:(NSEvent*)event
{
    NSString* pressedChars = [event characters];
    if([pressedChars length] == 1)
    {
        unichar pressedUnichar =
        [pressedChars characterAtIndex:0];
        
        // Delete key
        if(pressedUnichar == NSDeleteCharacter)
        {
            // Delete sequence
            if (self.sequenceTableView == self.sequenceTableView.window.firstResponder)
            {
                Sequence *sequence = [self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:sequence];
                [[CoreDataManager sharedManager] saveContext];
                
                if(self.sequenceFetchedResultsController.count == 0)
                {
                    self.createTrackButton.enabled = NO;
                    self.createTrackChannelButton.enabled = NO;
                }
            }
            // Delete track
            else if (self.trackTableView == self.trackTableView.window.firstResponder)
            {
                ControlBox *controlBox = [self.trackFetchedResultsController objectAtIndex:self.trackTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:controlBox];
                [[CoreDataManager sharedManager] saveContext];
                
                if(self.trackFetchedResultsController.count == 0)
                {
                    self.createTrackChannelButton.enabled = NO;
                }
            }
            // Delete track channel
            else if (self.trackChannelTableView == self.trackChannelTableView.window.firstResponder)
            {
                Channel *channel = [self.trackChannelFetchedResultsController objectAtIndex:self.trackChannelTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:channel];
                [[CoreDataManager sharedManager] saveContext];
            }
            // Delete lyric
            else if (self.lyricTableView == self.lyricTableView.window.firstResponder)
            {
                AudioLyric *lyric = [self.audioLyricFetchedResultsController objectAtIndex:self.lyricTableView.selectedRow];
                [[[CoreDataManager sharedManager] managedObjectContext] deleteObject:lyric];
                [[CoreDataManager sharedManager] saveContext];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        }
        else
        {
            [super keyDown:event];
        }
    }
}

#pragma mark - Buttons

- (IBAction)createSequenceButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newSequence];
}

- (IBAction)loadSequenceButtonPress:(id)sender
{
    Sequence *sequence = [self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow];
    [CoreDataManager sharedManager].currentSequence = sequence;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
}

- (IBAction)createTrackButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newAnalysisControlBoxForSequence:[self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
}

- (IBAction)createTrackChannelButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newChannelForControlBox:[self.trackFetchedResultsController objectAtIndex:self.trackTableView.selectedRow]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
}

- (IBAction)createLyricButtonPress:(id)sender
{
    [[CoreDataManager sharedManager] newAudioLyricForSequence:[self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
}

- (IBAction)chooseAudioFileButtonPress:(id)sender
{
    // Load the open panel if neccessary
    if(!self.openPanel)
    {
        self.openPanel = [NSOpenPanel openPanel];
        self.openPanel.canChooseDirectories = NO;
        self.openPanel.canChooseFiles = YES;
        self.openPanel.resolvesAliases = YES;
        self.openPanel.allowsMultipleSelection = NO;
        self.openPanel.allowedFileTypes = @[@"aac", @"aif", @"aiff", @"alac", @"mp3", @"m4a", @"wav"];
        //self.openPanel.directoryURL = [NSURL fileURLWithPathComponents:@[@"~", @"Music"]];
    }
    
    [self.openPanel beginWithCompletionHandler:^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSString *filePath = [[self.openPanel URL] path];
             //NSLog(@"filePath:%@", filePath);
             Sequence *selectedSequence = (Sequence *)[self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow];
             Audio *audio;
             if(!selectedSequence.audio)
             {
                 audio = [NSEntityDescription insertNewObjectForEntityForName:@"Audio" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                 audio.sequence = selectedSequence;
             }
             else
             {
                 audio = selectedSequence.audio;
             }
             
             // Set the data
             audio.audioFilePath = [filePath lastPathComponent];
             audio.audioFile = [NSData dataWithContentsOfFile:filePath];
             self.currentAudio = audio;
             
             [[CoreDataManager sharedManager] saveContext];
             
             // Search EchoNest for analysis
             if([filePath length] > 1)
             {
                 // See if the analysis has already been done
                 NSDictionary *parameters = @{@"md5" : [ENAPI calculateMD5DigestFromData:audio.audioFile], @"bucket" : @"audio_summary"};
                 [ENAPIRequest GETWithEndpoint:@"track/profile" andParameters:parameters andCompletionBlock:
                  ^(ENAPIRequest *request)
                  {
                      // Doesn't exist yet, needs uploading
                      if(![request.response[@"response"][@"track"][@"status"] isEqualToString:@"complete"])
                      {
                          // Upload the track
                          NSDictionary *parameters = @{@"track" : audio.audioFile, @"filetype" : [filePath pathExtension]};
                          [ENAPIRequest POSTWithEndpoint:@"track/upload" andParameters:parameters andCompletionBlock:
                           ^(ENAPIRequest *request)
                           {
                               //NSLog(@"upload request response:%@", request.response);
                               [self prepareForAudioAnalysisDownloadWithENAPIRequest:request andAudio:audio];
                           }];
                      }
                      // Already exists, skip to downloading analysis
                      else
                      {
                          [self prepareForAudioAnalysisDownloadWithENAPIRequest:request andAudio:audio];
                      }
                  }];
             }
         }
     }];
}

- (void)echoNestUploadUpdate:(NSNotification *)notification
{
    int bytesWritten = [notification.userInfo[@"totalBytesWritten"] intValue];
    int totalBytesToWrite = [notification.userInfo[@"totalBytesExpectedToWrite"] intValue];
    self.currentAudio.echoNestUploadProgress = @(0.8 * (float)bytesWritten / totalBytesToWrite);
    
    [self updateAudioAnlysisProgressLabel];
}

- (void)updateAudioAnlysisProgressLabel
{
    self.audioAnlysisProgress.stringValue = [NSString stringWithFormat:@"%.1f%%", 100 * [self.currentAudio.echoNestUploadProgress floatValue]];
}

- (void)prepareForAudioAnalysisDownloadWithENAPIRequest:(ENAPIRequest *)request andAudio:(Audio *)audio
{
    // Delete any old data
    if(audio.echoNestAudioAnalysis)
    {
        [[CoreDataManager sharedManager].managedObjectContext deleteObject:audio.echoNestAudioAnalysis];
    }
    
    EchoNestAudioAnalysis *echonestAudioAnalysis = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestAudioAnalysis" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
    echonestAudioAnalysis.audio = audio;
    echonestAudioAnalysis.idString = request.response[@"response"][@"track"][@"id"];
    audio.title = request.response[@"response"][@"track"][@"title"];
    self.audioDescriptionTextField.stringValue = audio.title;
    audio.echoNestUploadProgress = @(0.85);
    [self updateAudioAnlysisProgressLabel];
    
    [[CoreDataManager sharedManager] saveContext];
    
    // Download the audioanalysis
    [self checkForAudioAnalysisCompletionWithAudio:audio];
}

- (void)checkForAudioAnalysisCompletionWithAudio:(Audio *)audio
{
    if([audio.echoNestUploadProgress floatValue] < 0.95)
    {
        audio.echoNestUploadProgress = @([audio.echoNestUploadProgress floatValue] + 0.01);
        [self updateAudioAnlysisProgressLabel];
    }
    
    NSDictionary *parameters = @{@"id" : audio.echoNestAudioAnalysis.idString, @"bucket" : @"audio_summary"};
    [ENAPIRequest GETWithEndpoint:@"track/profile" andParameters:parameters andCompletionBlock:
     ^(ENAPIRequest *request)
     {
         //NSLog(@"summary request response:%@", request.response);
         
         // Analysis is ready for download
         if([request.response[@"response"][@"track"][@"status"] isEqualToString:@"complete"])
         {
             audio.echoNestUploadProgress = @(0.95);
             [self updateAudioAnlysisProgressLabel];
             
             // Store the analysisSummary data
             audio.echoNestAudioAnalysis.artistID = request.response[@"response"][@"track"][@"artist_id"];
             audio.echoNestAudioAnalysis.idString = request.response[@"response"][@"track"][@"id"];
             audio.echoNestAudioAnalysis.md5 = request.response[@"response"][@"track"][@"md5"];
             audio.echoNestAudioAnalysis.songID = request.response[@"response"][@"track"][@"song_id"];
             audio.echoNestAudioAnalysis.status = request.response[@"response"][@"track"][@"status"];
             audio.echoNestAudioAnalysis.acousticness = request.response[@"response"][@"track"][@"audio_summary"][@"acousticness"];
             audio.echoNestAudioAnalysis.analysisURL = request.response[@"response"][@"track"][@"audio_summary"][@"analysis_url"];
             audio.echoNestAudioAnalysis.danceability = request.response[@"response"][@"track"][@"audio_summary"][@"danceability"];
             audio.echoNestAudioAnalysis.energy = request.response[@"response"][@"track"][@"audio_summary"][@"energy"];
             audio.echoNestAudioAnalysis.instrumentalness = request.response[@"response"][@"track"][@"audio_summary"][@"instrumentalness"];
             audio.echoNestAudioAnalysis.liveness = request.response[@"response"][@"track"][@"audio_summary"][@"liveness"];
             audio.echoNestAudioAnalysis.loudness = request.response[@"response"][@"track"][@"audio_summary"][@"loudness"];
             audio.echoNestAudioAnalysis.speechiness = request.response[@"response"][@"track"][@"audio_summary"][@"speechiness"];
             audio.echoNestAudioAnalysis.tempo = request.response[@"response"][@"track"][@"audio_summary"][@"tempo"];
             audio.echoNestAudioAnalysis.valence = request.response[@"response"][@"track"][@"audio_summary"][@"valence"];
             
             // Download the full analysis
             [ENAPIRequest downloadAnalysisURL:audio.echoNestAudioAnalysis.analysisURL withCompletionBlock:
              ^(ENAPIRequest *request)
              {
                  //NSLog(@"analysis:%@", request.response);
                  audio.echoNestAudioAnalysis.album = request.response[@"meta"][@"album"];
                  audio.echoNestAudioAnalysis.analysisTime = request.response[@"meta"][@"analysis_time"];
                  audio.echoNestAudioAnalysis.analyzerVersion = request.response[@"meta"][@"analyzer_version"];
                  audio.echoNestAudioAnalysis.artist = request.response[@"meta"][@"artist"];
                  audio.echoNestAudioAnalysis.bitrate = request.response[@"meta"][@"bitrate"];
                  audio.echoNestAudioAnalysis.detailedStatus = request.response[@"meta"][@"detailed_status"];
                  audio.echoNestAudioAnalysis.fileName = request.response[@"meta"][@"filename"];
                  audio.echoNestAudioAnalysis.genre = request.response[@"meta"][@"genre"];
                  audio.echoNestAudioAnalysis.platform = request.response[@"meta"][@"platform"];
                  audio.echoNestAudioAnalysis.sampleRate = request.response[@"meta"][@"sample_rate"];
                  audio.echoNestAudioAnalysis.seconds = request.response[@"meta"][@"seconds"];
                  audio.echoNestAudioAnalysis.statusCode = request.response[@"meta"][@"status_code"];
                  audio.echoNestAudioAnalysis.timestamp = request.response[@"meta"][@"timestamp"];
                  audio.echoNestAudioAnalysis.title = request.response[@"meta"][@"title"];
                  self.audioDescriptionTextField.stringValue = audio.echoNestAudioAnalysis.title;
                  
                  audio.echoNestAudioAnalysis.analysisChannels = request.response[@"track"][@"analysis_channels"];
                  audio.echoNestAudioAnalysis.analysisSampleRate = request.response[@"track"][@"analysis_sample_rate"];
                  audio.echoNestAudioAnalysis.codeVersion = request.response[@"track"][@"code_version"];
                  audio.echoNestAudioAnalysis.codeString = request.response[@"track"][@"codestring"];
                  audio.echoNestAudioAnalysis.decoder = request.response[@"track"][@"decoder"];
                  audio.echoNestAudioAnalysis.decoderVersion = request.response[@"track"][@"decoder_version"];
                  audio.echoNestAudioAnalysis.duration = request.response[@"track"][@"duration"];
                  audio.echoNestAudioAnalysis.echoPrintVersion = request.response[@"track"][@"echoprint_version"];
                  audio.echoNestAudioAnalysis.echoPrintString = request.response[@"track"][@"echoprintstring"];
                  audio.echoNestAudioAnalysis.endOfFadeIn = request.response[@"track"][@"end_of_fade_in"];
                  audio.echoNestAudioAnalysis.key = request.response[@"track"][@"key"];
                  audio.echoNestAudioAnalysis.keyConfidence = request.response[@"track"][@"key_confidence"];
                  audio.echoNestAudioAnalysis.loudness = request.response[@"track"][@"loudness"];
                  audio.echoNestAudioAnalysis.mode = request.response[@"track"][@"mode"];
                  audio.echoNestAudioAnalysis.modeConfidence = request.response[@"track"][@"mode_confidence"];
                  audio.echoNestAudioAnalysis.numberOfSamples = request.response[@"track"][@"num_samples"];
                  audio.echoNestAudioAnalysis.offsetSeconds = request.response[@"track"][@"offset_seconds"];
                  audio.echoNestAudioAnalysis.rhythmVersion = request.response[@"track"][@"rhythm_version"];
                  audio.echoNestAudioAnalysis.rhythmString = request.response[@"track"][@"rhythmstring"];
                  audio.echoNestAudioAnalysis.sampleMD5 = request.response[@"track"][@"sample_md5"];
                  audio.echoNestAudioAnalysis.startOfFadeOut = request.response[@"track"][@"start_of_fade_out"];
                  audio.echoNestAudioAnalysis.synchVersion = request.response[@"track"][@"synch_version"];
                  audio.echoNestAudioAnalysis.synchString = request.response[@"track"][@"synchstring"];
                  audio.echoNestAudioAnalysis.tempo = request.response[@"track"][@"tempo"];
                  audio.echoNestAudioAnalysis.tempoConfidence = request.response[@"track"][@"tempo_confidence"];
                  audio.echoNestAudioAnalysis.timeSignature = request.response[@"track"][@"time_signature"];
                  audio.echoNestAudioAnalysis.timeSignatureConfidence = request.response[@"track"][@"time_signature_confidence"];
                  audio.echoNestAudioAnalysis.windowSeconds = request.response[@"track"][@"window_seconds"];
                  
                  // Store all the sections
                  NSArray *sections = request.response[@"sections"];
                  for(int i = 0; i < sections.count; i ++)
                  {
                      EchoNestSection *section = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestSection" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionarySection = sections[i];
                      section.confidence = dictionarySection[@"confidence"];
                      section.duration = dictionarySection[@"duration"];
                      section.key = dictionarySection[@"key"];
                      section.keyConfidence = dictionarySection[@"key_confidence"];
                      section.loudness = dictionarySection[@"loudness"];
                      section.mode = dictionarySection[@"mode"];
                      section.modeConfidence = dictionarySection[@"mode_confidence"];
                      section.start = dictionarySection[@"start"];
                      section.tempo = dictionarySection[@"tempo"];
                      section.tempoConfidence = dictionarySection[@"tempo_confidence"];
                      section.timeSignature = dictionarySection[@"time_signature"];
                      section.timeSignatureConfidence = dictionarySection[@"time_signature_confidence"];
                      [audio.echoNestAudioAnalysis addSectionsObject:section];
                  }
                  // Store all the bars
                  NSArray *bars = request.response[@"bars"];
                  for(int i = 0; i < bars.count; i ++)
                  {
                      EchoNestBar *bar = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestBar" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionaryBar = bars[i];
                      bar.confidence = dictionaryBar[@"confidence"];
                      bar.duration = dictionaryBar[@"duration"];
                      bar.start = dictionaryBar[@"start"];
                      [audio.echoNestAudioAnalysis addBarsObject:bar];
                  }
                  // Store all the beats
                  NSArray *beats = request.response[@"beats"];
                  for(int i = 0; i < beats.count; i ++)
                  {
                      EchoNestBeat *beat = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestBeat" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionaryBeat = beats[i];
                      beat.confidence = dictionaryBeat[@"confidence"];
                      beat.duration = dictionaryBeat[@"duration"];
                      beat.start = dictionaryBeat[@"start"];
                      [audio.echoNestAudioAnalysis addBeatsObject:beat];
                  }
                  // Store all the tatums
                  NSArray *tatums = request.response[@"tatums"];
                  for(int i = 0; i < tatums.count; i ++)
                  {
                      EchoNestTatum *tatum = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestTatum" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionaryTatum = tatums[i];
                      tatum.confidence = dictionaryTatum[@"confidence"];
                      tatum.duration = dictionaryTatum[@"duration"];
                      tatum.start = dictionaryTatum[@"start"];
                      [audio.echoNestAudioAnalysis addTatumsObject:tatum];
                  }
                  // Store all the segments
                  NSArray *segments = request.response[@"segments"];
                  for(int i = 0; i < segments.count; i ++)
                  {
                      EchoNestSegment *segment = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestSegment" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                      NSDictionary *dictionarySegment = segments[i];
                      segment.confidence = dictionarySegment[@"confidence"];
                      segment.duration = dictionarySegment[@"duration"];
                      segment.loudnessMax = dictionarySegment[@"loudness_max"];
                      segment.loudnessMaxTime = dictionarySegment[@"loudness_max_time"];
                      segment.loudnessStart = dictionarySegment[@"loudness_start"];
                      NSArray *pitches = dictionarySegment[@"pitches"];
                      for(int i2 = 0; i2 < pitches.count; i2 ++)
                      {
                          EchoNestPitch *pitch = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestPitch" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                          pitch.pitch = pitches[i2];
                          [segment addPitchesObject:pitch];
                      }
                      segment.start = dictionarySegment[@"start"];
                      NSArray *timbres = dictionarySegment[@"timbre"];
                      for(int i2 = 0; i2 < timbres.count; i2 ++)
                      {
                          EchoNestTimbre *timbre = [NSEntityDescription insertNewObjectForEntityForName:@"EchoNestTimbre" inManagedObjectContext:[CoreDataManager sharedManager].managedObjectContext];
                          timbre.timbre = timbres[i2];
                          [segment addTimbresObject:timbre];
                      }
                      
                      [audio.echoNestAudioAnalysis addSegmentsObject:segment];
                  }
                  
                  //audio.endOffset = audio.echoNestAudioAnalysis.startOfFadeOut;
                  //audio.startOffset = audio.echoNestAudioAnalysis.endOfFadeIn;
                  audio.sequence.endTime = audio.echoNestAudioAnalysis.duration;
                  audio.sequence.title = audio.echoNestAudioAnalysis.title;
                  [[CoreDataManager sharedManager] updateSequenceTatumsForNewAudioForSequence:audio.sequence];
                  
                  audio.echoNestUploadProgress = @(1.0);
                  [self updateAudioAnlysisProgressLabel];
                  [[CoreDataManager sharedManager] saveContext];
                  
                  [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
              }];
         }
         // Analysis isn't ready, keep polling
         else
         {
             [self performSelector:@selector(checkForAudioAnalysisCompletionWithAudio:) withObject:audio afterDelay:1.0];
         }
     }];
}

#pragma mark - NSTextFieldDelegate Methods

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if([control.identifier isEqualToString:@"sequenceTitleTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(Sequence *)[self.sequenceFetchedResultsController objectAtIndex:self.sequenceTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
            [[CoreDataManager sharedManager] saveContext];
        });
    }
    else if([control.identifier isEqualToString:@"trackTitleTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(ControlBox *)[self.trackFetchedResultsController objectAtIndex:self.trackTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
            [[CoreDataManager sharedManager] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        });
    }
    else if([control.identifier isEqualToString:@"trackChannelTextField"])
    {
        [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:self.trackChannelTableView.selectedRow] setTitle:[(NSTextField *)control stringValue]];
        [[CoreDataManager sharedManager] saveContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
    }
    else if([control.identifier isEqualToString:@"trackChannelPitchTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:self.trackChannelTableView.selectedRow] setIdNumber:@([(NSTextField *)control intValue])];
            [[CoreDataManager sharedManager] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        });
    }
    else if([control.identifier isEqualToString:@"timeTextField"])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [(AudioLyric *)[self.audioLyricFetchedResultsController objectAtIndex:self.lyricTableView.selectedRow] setTime:@([(NSTextField *)control floatValue])];
            [[CoreDataManager sharedManager] saveContext];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
        });
    }
    else if([control.identifier isEqualToString:@"lyricTextField"])
    {
        [(AudioLyric *)[self.audioLyricFetchedResultsController objectAtIndex:self.lyricTableView.selectedRow] setText:[(NSTextField *)control stringValue]];
        [[CoreDataManager sharedManager] saveContext];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSequenceChange" object:nil];
    }
    
    return YES;
}

- (IBAction)colorChange:(id)sender
{
    int tableRow = [(ChannelColorTableCellView *)[(NSColorWell *)sender superview] tableRow];
    [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:tableRow] setColor:[(NSColorWell *)sender color]];
    [[CoreDataManager sharedManager] saveContext];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == self.sequenceTableView)
    {
        return [self.sequenceFetchedResultsController count];
    }
    else if(aTableView == self.trackTableView)
    {
        return [self.trackFetchedResultsController count];
    }
    else if(aTableView == self.trackChannelTableView)
    {
        return [self.trackChannelFetchedResultsController count];
    }
    else if(aTableView == self.lyricTableView)
    {
        return [self.audioLyricFetchedResultsController count];
    }
    
    return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.sequenceTableView)
    {
        // Title column
        if([tableColumn.identifier isEqualToString:@"sequenceTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"sequenceTitleView" owner:self];
            result.textField.stringValue = [(Sequence *)[self.sequenceFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    else if(tableView == self.trackTableView)
    {
        // Title column
        if([tableColumn.identifier isEqualToString:@"trackTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"trackTitleView" owner:self];
            result.textField.stringValue = [(ControlBox *)[self.trackFetchedResultsController objectAtIndex:row] title];
            return result;
        }
    }
    else if(tableView == self.trackChannelTableView)
    {
        // ID column
        if([tableColumn.identifier isEqualToString:@"trackChannelPitch"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"trackChannelPitchView" owner:self];
            result.textField.integerValue = [[(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:row] idNumber] integerValue];
            return result;
        }
        // Title column
        else if([tableColumn.identifier isEqualToString:@"trackChannelTitle"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"trackChannelTitleView" owner:self];
            result.textField.stringValue = [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:row] title];
            return result;
        }
        // Color column
        else if([tableColumn.identifier isEqualToString:@"color"])
        {
            ChannelColorTableCellView *result = [tableView makeViewWithIdentifier:@"channelColor" owner:self];
            result.colorWell.color = [(Channel *)[self.trackChannelFetchedResultsController objectAtIndex:row] color];
            result.tableRow = (int)row;
            return  result;
        }
    }
    else if(tableView == self.lyricTableView)
    {
        // Time column
        if([tableColumn.identifier isEqualToString:@"time"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"timeView" owner:self];
            result.textField.floatValue = [[(AudioLyric *)[self.audioLyricFetchedResultsController objectAtIndex:row] time] floatValue];
            return result;
        }
        // Lyric column
        else if([tableColumn.identifier isEqualToString:@"lyric"])
        {
            NSTableCellView *result = [tableView makeViewWithIdentifier:@"lyricView" owner:self];
            result.textField.stringValue = [(AudioLyric *)[self.audioLyricFetchedResultsController objectAtIndex:row] text];
            return result;
        }
    }
    
    // Return the result
    return nil;
}

#pragma mark - NSTableViewDelegate Methods

-(BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if(tableView == self.sequenceTableView)
    {
        self.createTrackButton.enabled = YES;
        self.createLyricButton.enabled = YES;
        
        Sequence *sequence = (Sequence *)[self.sequenceFetchedResultsController objectAtIndex:row];
        [self updateTrackFetchedResultsControllerForSequence:sequence];
        [self updateAudioLyricFetchedResultsControllerForAudio:sequence.audio];
        
        NSError *error = nil;
        if (![[self trackFetchedResultsController] performFetch:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
        [self.trackTableView reloadData];
        
        // Show the audio data
        if(self.sequenceFetchedResultsController.count > row)
        {
            if(sequence.audio.title.length > 0)
            {
                self.audioDescriptionTextField.stringValue = sequence.audio.title;
            }
            self.currentAudio = sequence.audio;
            [self updateAudioAnlysisProgressLabel];
            [self updateAudioTitleLabelForSequenceAtRow:(int)row];
        }
    }
    else if(tableView == self.trackTableView)
    {
        self.createTrackChannelButton.enabled = YES;
        
        [self updateTrackChannelFetchedResultsControllerForTrack:(ControlBox *)[self.trackFetchedResultsController objectAtIndex:row]];
        NSError *error = nil;
        if (![[self trackChannelFetchedResultsController] performFetch:&error])
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            [[NSApplication sharedApplication] presentError:error];
        }
        [self.trackChannelTableView reloadData];
    }
    
    return YES;
}

#pragma mark - Fetched results controller

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)sequenceFetchedResultsController
{
    if (_sequenceFetchedResultsController != nil)
    {
        return _sequenceFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Sequence"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _sequenceFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _sequenceFetchedResultsController.delegate = self;
    
    return _sequenceFetchedResultsController;
}

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)trackFetchedResultsController
{
    if (_trackFetchedResultsController != nil)
    {
        return _trackFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ControlBox"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"idNumber" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _trackFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _trackFetchedResultsController.delegate = self;
    
    return _trackFetchedResultsController;
}

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)trackChannelFetchedResultsController
{
    if (_trackChannelFetchedResultsController != nil)
    {
        return _trackChannelFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Channel"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"idNumber" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _trackChannelFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _trackChannelFetchedResultsController.delegate = self;
    
    return _trackChannelFetchedResultsController;
}

// Returns the fetched results controller. Creates and configures the controller if necessary.
- (SNRFetchedResultsController *)audioLyricFetchedResultsController
{
    if (_audioLyricFetchedResultsController != nil)
    {
        return _audioLyricFetchedResultsController;
    }
    
    // Create and configure a fetch request with the Book entity.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"AudioLyric"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]];
    
    // Create and initialize the fetch results controller.
    _audioLyricFetchedResultsController = [[SNRFetchedResultsController alloc] initWithManagedObjectContext:[[CoreDataManager sharedManager] managedObjectContext] fetchRequest:fetchRequest];
    _audioLyricFetchedResultsController.delegate = self;
    
    return _audioLyricFetchedResultsController;
}

- (void)updateTrackFetchedResultsControllerForSequence:(Sequence *)sequence
{
    self.trackFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"analysisSequence == %@", sequence];
}

- (void)updateTrackChannelFetchedResultsControllerForTrack:(ControlBox *)track
{
    self.trackChannelFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"controlBox == %@", track];
}

- (void)updateAudioLyricFetchedResultsControllerForAudio:(Audio *)audio
{
    self.audioLyricFetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"audio == %@", audio];
}

// NSFetchedResultsController delegate methods to respond to additions, removals and so on.
- (void)controllerWillChangeContent:(SNRFetchedResultsController *)controller
{
    if(controller == self.sequenceFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.sequenceTableView beginUpdates];
    }
    else if(controller == self.trackFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.trackTableView beginUpdates];
    }
    else if(controller == self.trackChannelFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.trackChannelTableView beginUpdates];
    }
    else if(controller == self.audioLyricFetchedResultsController)
    {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
        [self.lyricTableView beginUpdates];
    }
}

- (void)controller:(SNRFetchedResultsController *)controller didChangeObject:(id)anObject atIndex:(NSUInteger)index forChangeType:(SNRFetchedResultsChangeType)type newIndex:(NSUInteger)newIndex
{
    NSTableView *tableView;
    if(controller == self.sequenceFetchedResultsController)
    {
        tableView = self.sequenceTableView;
    }
    else if(controller == self.trackFetchedResultsController)
    {
        tableView = self.trackTableView;
    }
    else if(controller == self.trackChannelFetchedResultsController)
    {
        tableView = self.trackChannelTableView;
    }
    else if(controller == self.audioLyricFetchedResultsController)
    {
        tableView = self.lyricTableView;
    }
    
    switch (type)
    {
        case SNRFetchedResultsChangeDelete:
            [tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideLeft];
            break;
        case SNRFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndex] withAnimation:NSTableViewAnimationSlideDown];
            break;
        case SNRFetchedResultsChangeUpdate:
            [tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            break;
        case SNRFetchedResultsChangeMove:
            [tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationSlideLeft];
            [tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:newIndex] withAnimation:NSTableViewAnimationSlideDown];
            break;
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(SNRFetchedResultsController *)controller
{
    if(controller == self.sequenceFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.sequenceTableView endUpdates];
    }
    else if(controller == self.trackFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.trackTableView endUpdates];
    }
    else if(controller == self.trackChannelFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.trackChannelTableView endUpdates];
    }
    else if(controller == self.audioLyricFetchedResultsController)
    {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
        [self.lyricTableView endUpdates];
    }
}

@end
