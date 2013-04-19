//
//  SoundPlayer.m
//  PianoScribe
//
//  Created by Wenley Tong on 3/3/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import "SoundPlayer.h"
#import "PSFirstViewController.h"
#import "PSNoteHypothesis.h"

@interface PSSoundPlayer()

@property (retain) NSArray * soundData;
@property (retain) NSArray * fourierData;

@end

@implementation PSSoundPlayer

@synthesize in;
@synthesize out;
@synthesize session;
@synthesize delegate;
@synthesize fourierData, soundData;

- (id) init
{
   NSMutableDictionary * settings;
   if (self = [super init]) {
      self.session = [AVAudioSession sharedInstance];
      NSError * err = nil;
      [self.session setCategory:AVAudioSessionCategoryPlayAndRecord
                          error:&err];
      if (err) {
         NSLog(@"When setting category");
         NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
      }
      [self.session setActive:YES error:&err];
      if (err) {
         NSLog(@"When setting active");
         NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
      }
      
      soundFile = [NSURL URLWithString:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/test.caf"]];
      settings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                  [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                  [NSNumber numberWithFloat:44100], AVSampleRateKey,
                  [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                  [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                  [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                  [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                  nil];
      
      self.in = [[AVAudioRecorder alloc] initWithURL:soundFile
                                            settings:settings
                                               error:&err];
      if (err || !self.in) {
         NSLog(@"Recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
      }
      if (![self.in prepareToRecord])
         NSLog(@"Can't record! OH NOEZ");
      
      //  Mark as no recording made 
      secondsRecorded = 0.0;
      
//      NSString * pathToNoteWaves = [[NSBundle mainBundle] pathForResource:@"data008" ofType:nil];
//      NSArray * fileList = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathToNoteWaves error:nil];
//      NSLog(@"Files at path %@: %d", pathToNoteWaves, fileList.count);
//      database = [[PSNoteDatabase alloc] initFromDirectory:pathToNoteWaves];
   }
   return self;
}

/* - - - - - UI Interaction events - - - - - */
- (void)startPlaying
{
   NSError * err;
   self.out = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFile
                                                     error:&err];
   [self.out setDelegate:self];
   if (err)
      NSLog(@"Error from player creating is %@", err);
   
   if (self.paused)
      [self.out play];
}
- (void)startRecording
{
   NSError * err;
   [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&err];
   if (self.paused) {
      if (![self.in prepareToRecord])
         NSLog(@"Cannot prepare");
      else
         [self.in record];
   }
}
- (NSTimeInterval)pause
{
   NSError * err;
   [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&err];
   NSTimeInterval elapsed = 0.0;
   if (self.playing) {
      elapsed = [self.out currentTime];
      [self.out pause];
   }
   else if (self.recording) {
      elapsed = [self.in currentTime];
      secondsRecorded = elapsed;
      [self.in stop];
      
      UInt64 length = 0, offset;
      
      //  Store data from file
      NSString * pathToDataFile = [[NSBundle mainBundle] pathForResource:@"data008/C4" ofType:nil];
      NSString * contents = [NSString stringWithContentsOfFile:pathToDataFile encoding:NSASCIIStringEncoding error:NULL];
      NSArray * lines = [contents componentsSeparatedByString:@"\n"];
      AudioSampleType * data = calloc(lines.count, sizeof(AudioSampleType));
      for (int i = 0; i < lines.count; i++) {
         NSString * line = [lines objectAtIndex:i];
         data[i] = [line intValue];
      }
      length = lines.count;
      offset = 0;

      //  Get data from sound recording
//      AudioSampleType * data = [self getSoundDataWithLength:&length];
//      offset = 32;
//      NSLog(@"data is null? %d", data == NULL);

      NSMutableArray * temp = [NSMutableArray array];
      for (int i = 0 + offset; i < 2048 + offset; i++) {
         [temp addObject:[NSNumber numberWithDouble:data[i]/32768.0]]; //  Convert to double!!!
//         NSLog(@"%d --> %@", data[i], [temp objectAtIndex:i]);
//         printf("%d\n", data[i]);
      }
      
      //  Temporary to show graph
      self.soundData = temp;
      self.fourierData = [PSFourierWorker initTransformToFrequency:self.soundData];
      
//      [self processRecordingWithData:data ofLength:length];
      NSString * tinyDir = [[NSBundle mainBundle] pathForResource:@"tiny" ofType:nil];
      NSString * tinyTestDir = [[NSBundle mainBundle] pathForResource:@"testtiny" ofType:nil];
      PSNoteDatabase * db = [[PSNoteDatabase alloc] initFromDirectory:tinyDir];
      NSString * signalContents = [NSString stringWithContentsOfFile:[tinyTestDir stringByAppendingPathComponent:@"test1"]
                                                       encoding:NSASCIIStringEncoding error:nil];
      NSArray * vals = [[signalContents componentsSeparatedByString:@"\n"] subarrayWithRange:NSMakeRange(0, WINDOW_SIZE)];
      NSMutableArray * sig = [NSMutableArray arrayWithCapacity:vals.count];
      for (NSString * v in vals)
         [sig addObject:[NSNumber numberWithDouble:v.doubleValue / 32768.0]];
      [db bestHypothesisForSignal:[sig subarrayWithRange:NSMakeRange(0, WINDOW_SIZE)]];
      
//      NSLog(@"Fourier data has length: %d", [self.fourierData count]);
   }
   return elapsed;
}

- (BOOL)playing {
   return self.out.playing;
}
- (BOOL)recording {
   return self.in.recording;
}
- (BOOL)paused {
   return !self.playing && !self.recording;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
   [delegate audioPlayerDidFinishPlayingSuccessfully:flag afterTime:[player duration]];
}

/* - - - - - Plotting reporting methods - - - - - */
- (NSInteger) numberOfRecords
{
   if (secondsRecorded == 0.0)
      return 0;
   else
      return [self.soundData count];
}
- (NSNumber *) dataRecordAtIndex:(NSInteger)index
{
   if (secondsRecorded == 0.0)
      return nil;
   else if ([self.soundData count] < index || index < 0)
      return nil;
   else
      return (NSNumber *) [self.soundData objectAtIndex:index];
}
- (NSNumber *) fourierRecordAtIndex:(NSInteger)index
{
   if (secondsRecorded == 0.0)
      return nil;
   else if ([self.fourierData count] <= index || index < 0)
      return [NSNumber numberWithDouble:0.0];
   else {
      double value = ((NSNumber *) [self.fourierData objectAtIndex:index]).doubleValue;
      return [NSNumber numberWithDouble:value / 1000];
   }
}

/* - - - - - Fourier Processing - - - - - */
double * zeroPhaseIIRFilter(double * data, UInt64 length)
{
//   AudioSampleType * y = calloc(length, sizeof(AudioSampleType));
//   AudioSampleType * z = calloc(length, sizeof(AudioSampleType));
//   for (int i = 2; i < length - 2; i++) {
//      y[i] = (AudioSampleType) (0.5 * data[i] + 0.15 * (data[i-1] + data[i+1]) + 0.1 * (data[i-2] + data[i+2]));
//      NSLog(@"Simple average: i = %d, x[i] = %d, y[i] = %d", i, data[i], y[i]);
//   }
//   y[0]          = 0.75 * data[0] + 0.15 * data[1] + 0.1 * data[2];
//   y[length - 1] = 0.75 * data[length - 1] + 0.15 * data[length - 2] + 0.1 * data[length - 3];
//   y[1] = 0.6 * data[1] + 0.15 * (data[0] + data[2]) + 0.1 * data[3];
//   y[length - 2] = 0.6 * data[length - 2] + 0.15 * (data[length - 1] + data[length - 3]) + 0.1 * data[length - 4];
//   for (int i = 2; i < length - 2; i++) {
//      z[i] = (AudioSampleType) (y[i]);
//      
//   }
   
   double * filter1 = IIRFilter(data, length);
   reverse(filter1, length);
   double * filter2 = IIRFilter(filter1, length);
   reverse(filter2, length);

   free(filter1);
   return filter2;
}

//  Low-pass IIR filter from Wikipedia
double * IIRFilter(double * data, UInt64 length)
{
   double * y = calloc(length, sizeof(double));
   
   double alpha = 0.6;
   y[0] = data[0];
   for (int i = 1; i < length; i++)
      y[i] = alpha * data[i] + (1-alpha) * y[i-1];
   
   return y;
}

//  In-place reversal of the array data
void reverse(double * data, UInt64 length)
{
   for (int i = 0; i < length / 2; i++) {
      double x = data[i];
      data[i] = data[length - 1 - i];
      data[length - 1 - i] = x;
   }
}

typedef struct {
   double energy;
   int index;
} peak_t;

CFComparisonResult comparePeaks(const void * p1, const void * p2, void * info)
{
   peak_t * one = (peak_t *) p1;
   peak_t * two = (peak_t *) p2;
   if (one->energy > two->energy)
      return kCFCompareGreaterThan;
   else if (one->energy < two->energy)
      return kCFCompareLessThan;
   else
      return kCFCompareEqualTo;
}

- (void) processRecordingWithData:(AudioSampleType *) data ofLength:(UInt64) length {
   NSLog(@"Would process data with length %llu", length);
   if (data == nil || data == NULL)
      NSLog(@"...but data is nil?");
   free(data);
   
   NSAssert(self.fourierData != NULL, @"fourier data is null!");
   
   //  To zero-shift IIR filter //
   UInt64 len = self.fourierData.count;
   double * fourier = calloc(len, sizeof(double));
   for (int i = 0; i < len; i++)
      fourier[i] = ((NSNumber *) [self.fourierData objectAtIndex:i]).doubleValue;
   double * filtered = zeroPhaseIIRFilter(fourier, len);
   NSMutableArray * filteredData = [NSMutableArray arrayWithCapacity:self.fourierData.count];
   for (int i = 0; i < len; i++) {
      [filteredData addObject:[NSNumber numberWithDouble:filtered[i]]];
      if (i < 20)
         NSLog(@"index %d, value %f", i, filtered[i]);
   }
   
   //  Look for local peaks with window size 5
   unsigned Mmax = 12;
   unsigned P = 10;
   unsigned Z = 5;

   NSMutableArray * peaks = [[NSMutableArray alloc] initWithCapacity:length];
   CFBinaryHeapCallBacks callbacks;
   callbacks.version = 0;
   callbacks.retain = NULL;
   callbacks.release = NULL;
   callbacks.copyDescription = NULL;
   callbacks.compare = comparePeaks;
   CFBinaryHeapRef maxes = CFBinaryHeapCreate(NULL, P+1, &callbacks, NULL);
   for (int i = 0; i < self.fourierData.count; i++) {
      if ( (i >= 2 && filtered[i] < filtered[i - 2]) ||
           (i >= 1 && filtered[i] < filtered[i - 1]) ||
           (i <= length - 2 && filtered[i] < filtered[i + 1]) ||
           (i <= length - 3 && filtered[i] < filtered[i + 2]))
         [peaks addObject:[NSNumber numberWithDouble:0]];
      else {
         peak_t * p = calloc(1, sizeof(peak_t));
         p->index = i;
         p->energy = filtered[i];
         CFBinaryHeapAddValue(maxes, p);
         if (CFBinaryHeapGetCount(maxes) > P)
            CFBinaryHeapRemoveMinimumValue(maxes);
         [peaks addObject:[NSNumber numberWithDouble:filtered[i]]];
//         NSLog(@"Peak at index %d with energy %f", i, filtered[i]);
      }
   }
   NSLog(@"Number of peaks kept: %ld", CFBinaryHeapGetCount(maxes));
   peak_t ** maxPeaks = calloc(P, sizeof(peak_t *));
   NSMutableArray * temp = [NSMutableArray arrayWithCapacity:P];
   CFBinaryHeapGetValues(maxes, (const void **) maxPeaks);
   double freqPerBin = 44100.0 / self.soundData.count;
   for (int i = P-1; i >= 0; i--) {
      NSLog(@"Peak %d: at index %d, energy %f", i, maxPeaks[i]->index, maxPeaks[i]->energy);
      NSMutableArray * innerTemp = [NSMutableArray arrayWithCapacity:Z];
      for (int j = 1; j <= Z; j++) {
         int index = maxPeaks[i]->index / j;
         double freq = freqPerBin * index;
         [innerTemp addObject:[[PSNoteHypothesis alloc] initWithFrequency:freq atIndex:index ofArray:filteredData]];
      }
      [temp addObject:innerTemp.copy];
      free(maxPeaks[i]);
   }
   NSArray * hypotheses = temp;
   for (NSArray * x in hypotheses) {
      for (PSNoteHypothesis * n in x) {
         [n findComb:Mmax];
         if ([n hasMinimumSupport:3 andEnergy:500.0])
            NSLog(@"Kept %@", n);
      }
   }
   
   //  Test code for NoteDatabase
//   [database bestHypothesisForSignal:self.soundData];
   NSString * tinyDir = [[NSBundle mainBundle] pathForResource:@"tiny" ofType:nil];
   NSString * tinyTestDir = [[NSBundle mainBundle] pathForResource:@"tinytest" ofType:nil];
   PSNoteDatabase * db = [[PSNoteDatabase alloc] initFromDirectory:tinyDir];
   NSArray * sig = [[NSString stringWithContentsOfFile:[tinyTestDir stringByAppendingPathComponent:@"test1"]
                                              encoding:NSASCIIStringEncoding error:nil]
                    componentsSeparatedByString:@"\n"];
   [db bestHypothesisForSignal:sig];
   
   
   //  Phase Vocoder relevant when processing whole stream with windows
   //  Hanning Windows to minimize window effects
   //  NSArray * trueFrequencies = phaseVocoder(self.fourierData, self.soundData);
   
   free(maxPeaks);
   free(fourier);
   free(filtered);
   //  Pick fundamentals //
   //  Adjust frequencies of fundamentals by phase-vocoder technique //
   //  Filter combs by heuristics
   //  - Minimum support by partials
   //  - Minimum energy (how to convert current units to energy?)
   //  - Detection of sub-harmonics (compare sums of even vs. odd of lower fundamental
   //  - "     " (compare first 4 partials' energy to total)
   //  - Detection of overtones (compare total energy of high to first 4 partials')
   //  - Harmonic overlapping
}

- (AudioSampleType *)getSoundDataWithLength:(UInt64 *)length {
   NSLog (@"readAudioFilesIntoMemory - file %@", soundFile);
   
   // Instantiate an extended audio file object.
   ExtAudioFileRef audioFileObject = 0;
   
   // Open an audio file and associate it with the extended audio file object.
   OSStatus result = ExtAudioFileOpenURL ((__bridge CFURLRef)soundFile, &audioFileObject);
   
   // Get the audio file's length in frames.
   UInt64 totalFramesInFile = 0;
   UInt32 frameLengthPropertySize = sizeof (totalFramesInFile);
   
   result =    ExtAudioFileGetProperty (
                                        audioFileObject,
                                        kExtAudioFileProperty_FileLengthFrames,
                                        &frameLengthPropertySize,
                                        &totalFramesInFile
                                        );
   
   // Get the audio file's number of channels.
   AudioStreamBasicDescription fileAudioFormat = {0};
   UInt32 formatPropertySize = sizeof (fileAudioFormat);
   
   result =    ExtAudioFileGetProperty (
                                        audioFileObject,
                                        kExtAudioFileProperty_FileDataFormat,
                                        &formatPropertySize,
                                        &fileAudioFormat
                                        );
   
   UInt32 channelCount = fileAudioFormat.mChannelsPerFrame;
   
   // Allocate memory in the soundStructArray instance variable to hold the left channel,
   //    or mono, audio data
   AudioSampleType * audioDataLeft = (AudioSampleType *) calloc (totalFramesInFile, sizeof (AudioSampleType));
   
   AudioStreamBasicDescription importFormat = {0};
   importFormat.mFormatID          = kAudioFormatLinearPCM;
   importFormat.mFormatFlags       = kAudioFormatFlagsCanonical;
   importFormat.mBytesPerPacket    = sizeof(AudioSampleType);
   importFormat.mFramesPerPacket   = 1;
   importFormat.mBytesPerFrame     = sizeof(AudioSampleType);
   importFormat.mChannelsPerFrame  = 1;                  // 1 indicates mono
   importFormat.mBitsPerChannel    = 8 * sizeof(AudioSampleType);
   importFormat.mSampleRate        = 44100.0;
   
   
   // Assign the appropriate mixer input bus stream data format to the extended audio
   //        file object. This is the format used for the audio data placed into the audio
   //        buffer in the SoundStruct data structure, which is in turn used in the
   //        inputRenderCallback callback function.
   
   result =    ExtAudioFileSetProperty (
                                        audioFileObject,
                                        kExtAudioFileProperty_ClientDataFormat,
                                        sizeof (importFormat),
                                        &importFormat
                                        );
   
   // Set up an AudioBufferList struct, which has two roles:
   //
   //        1. It gives the ExtAudioFileRead function the configuration it
   //            needs to correctly provide the data to the buffer.
   //
   //        2. It points to the soundStructArray[audioFile].audioDataLeft buffer, so
   //            that audio data obtained from disk using the ExtAudioFileRead function
   //            goes to that buffer
   
   // Allocate memory for the buffer list struct according to the number of
   //    channels it represents.
   AudioBufferList *bufferList;
   
   bufferList = (AudioBufferList *) malloc (
                                            sizeof (AudioBufferList) + sizeof (AudioBuffer) * (channelCount - 1)
                                            );
   
   if (NULL == bufferList) {NSLog (@"*** malloc failure for allocating bufferList memory"); return nil;;}
   
   // initialize the mNumberBuffers member
   bufferList->mNumberBuffers = channelCount;
   
   // initialize the mBuffers member to 0
   AudioBuffer emptyBuffer = {0};
   size_t arrayIndex;
   for (arrayIndex = 0; arrayIndex < channelCount; arrayIndex++) {
      bufferList->mBuffers[arrayIndex] = emptyBuffer;
   }
   
   // set up the AudioBuffer structs in the buffer list
   bufferList->mBuffers[0].mNumberChannels  = 1;
   bufferList->mBuffers[0].mDataByteSize    = totalFramesInFile * sizeof (AudioSampleType);
   bufferList->mBuffers[0].mData            = audioDataLeft;
   
   // Perform a synchronous, sequential read of the audio data out of the file and
   //    into the soundStructArray[audioFile].audioDataLeft and (if stereo) .audioDataRight members.
   UInt32 numberOfPacketsToRead = (UInt32) totalFramesInFile;
   
   result = ExtAudioFileRead (
                              audioFileObject,
                              &numberOfPacketsToRead,
                              bufferList
                              );
   NSLog(@"FROM BORROWED: Read %lu bytes into buffers", numberOfPacketsToRead);
   NSLog(@"Asked for %llu bytes", totalFramesInFile);
   
   free (bufferList);
   
   if (noErr != result) {
      
      // If reading from the file failed, then free the memory for the sound buffer.
      free (audioDataLeft);
      audioDataLeft = 0;
      ExtAudioFileDispose (audioFileObject);
      return nil;
   }
   
   NSLog (@"Finished reading file %@ into memory", soundFile);
   
   // Dispose of the extended audio file object, which also
   //    closes the associated file.
   ExtAudioFileDispose (audioFileObject);
   *length = numberOfPacketsToRead;
   return audioDataLeft;
}


@end
