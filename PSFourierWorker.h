//
//  PSFourierWorker.h
//  PianoScribe
//
//  Created by Wenley Tong on 13/3/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <Accelerate/Accelerate.h>

@interface PSFourierWorker : NSObject

+ (NSArray *) initTransformToFrequency:(NSArray *)array;
+ (NSArray *) initTransformToTime:(NSArray *)array;

@end
