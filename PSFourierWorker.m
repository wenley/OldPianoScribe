//
//  PSFourierWorker.m
//  PianoScribe
//
//  Created by Wenley Tong on 13/3/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import "PSFourierWorker.h"

@interface PSFourierWorker()

+ (NSArray *) initTransform:(NSArray *)array inDirection:(FFTDirection) dir;

//  Convert between NSArray[SInt16] and double[]
+ (NSArray *) initNSArrayFromDouble:(double *)array ofLength:(size_t) length;
+ (double *) initDoubleArrayFromNSArray:(NSArray *)array;

//  Performs FFT on a double[]
+ (double *) fftArray:(double *)array ofLogLength:(vDSP_Length)log2n inDirection:(FFTDirection) dir;

@end

@implementation PSFourierWorker

/* - - - - - Outward Facing Functions - - - - - */
+ (NSArray *) initTransformToFrequency:(NSArray *)array
{
   return [PSFourierWorker initTransform:array inDirection:kFFTDirection_Forward];
}

+ (NSArray *) initTransformToTime:(NSArray *)array
{
//   return [PSFourierWorker initTransform:array inDirection:kFFTDirection_Inverse];
   return nil;
}

+ (NSArray *) initTransform:(NSArray *)array inDirection:(FFTDirection) dir
{
   double * data = [PSFourierWorker initDoubleArrayFromNSArray:array];
   vDSP_Length logLen = -1;
   NSUInteger length = [array count];
   while (length > 0) {
      logLen++;
      length >>= 1;
   }
   NSLog(@"Len = %u, Loglen = %lu", array.count, logLen);
   
   //for (int i = 0; i < array.count; i++)
   //   NSLog(@"to fourier: index %d, value %f", i, data[i]);
   
   NSLog(@"Computed logLen: %lu", logLen);
   double * result = [PSFourierWorker fftArray:data ofLogLength:logLen inDirection:dir];
   free(data);
   
   NSArray * output = [PSFourierWorker initNSArrayFromDouble:result ofLength:[array count]/2];
   free(result);
   
   return output;
}

/* - - - - - Convert data structures - - - - - */
+ (NSArray *) initNSArrayFromDouble:(double *)array ofLength:(size_t) length
{
   NSMutableArray * data = [[NSMutableArray alloc] init];
   for (int i = 0; i < length; i++)
      [data addObject:[NSNumber numberWithDouble:array[i]]];
   return data;
}

+ (double *) initDoubleArrayFromNSArray:(NSArray *)array
{
   double * data = calloc([array count], sizeof(double));
   for (int i = 0; i < [array count]; i++)
      data[i] = ((NSNumber *)[array objectAtIndex:i]).doubleValue;
   return data;
}

/* - - - - - Actual FFT Work - - - - - */
+ (double *) fftArray:(double *)array ofLogLength:(vDSP_Length)log2n inDirection:(FFTDirection) dir{
   
   size_t length = 1 << log2n;
   
   FFTSetupD setup = vDSP_create_fftsetupD(log2n, kFFTRadix2);
   DSPDoubleSplitComplex data;
   data.realp = calloc(length / 2, sizeof(double));
   data.imagp = calloc(length / 2, sizeof(double));
   vDSP_ctozD((DSPDoubleComplex *)array, 2, &data, 1, length / 2);

   double * output = calloc(length/2, sizeof(double));
   const double scale = 1.0/2;
   vDSP_fft_zripD(setup, &data, 1, log2n, kFFTDirection_Forward);
   vDSP_vsmulD(data.realp, 1, &scale, data.realp, 1, length/2);
   vDSP_vsmulD(data.imagp, 1, &scale, data.imagp, 1, length/2);
   vDSP_zvmagsD(&data, 1, output, 1, length/2);
   
   free(data.realp);
   free(data.imagp);
   vDSP_destroy_fftsetupD(setup);
   
   return output;
}

@end
