//
//  PSSoundPlayer.h
//  PianoScribe
//
//  Created by Wenley Tong on 13/3/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVAudioRecorder.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "PSFourierWorker.h"

@class PSFirstViewController;

@interface PSSoundPlayer : NSObject <AVAudioPlayerDelegate> {
   @private NSURL * soundFile;
   @private NSArray * recordings;
   @private AVAudioSession * session;
   @private AVAudioPlayer * out;
   @private AVAudioRecorder * in;
   @private ExtAudioFileRef * audioFile;
   @private double secondsRecorded;
   
   @private PSFirstViewController * controller;
   
   @private NSArray * soundData;
   @private NSArray * fourierData;
}

@property AVAudioSession * session;
@property AVAudioRecorder * in;
@property AVAudioPlayer * out;
@property (assign) PSFirstViewController * delegate;

@property (readonly) int numRecordings;
@property (readonly) BOOL recording;
@property (readonly) BOOL playing;
@property (readonly) BOOL paused;
@property (readonly) BOOL hasRecording;

- (void) startRecording;
- (void) startPlaying;
- (NSTimeInterval) pause;

//  Plotting information reporting
- (NSInteger) numberOfRecords;
- (NSNumber *) dataRecordAtIndex:(NSInteger)index;
- (NSNumber *) fourierRecordAtIndex:(NSInteger)index;

@end
