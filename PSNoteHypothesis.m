//
//  PSNoteHypothesis.m
//  PianoScribe
//
//  Created by Wenley Tong on 5/4/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import "PSNoteHypothesis.h"

@implementation PSNoteHypothesis

@synthesize fundamental;
@synthesize index = fundamentalIndex;
@synthesize comb;

- (id) initWithFrequency:(double) fundFreq atIndex:(unsigned) fundIdx ofArray:(NSArray *)energyArray
{
   self = [super init];
   if (self != nil) {
      fundamental = fundFreq;
      fundamentalIndex = fundIdx;
      energies = energyArray;
   }
   return self;
}

- (void) findComb:(unsigned) numPeaks
{
   NSMutableArray * temp = [[NSMutableArray alloc] initWithCapacity:numPeaks];
   for (int i = 1; i <= numPeaks; i++) {
      if (i*fundamentalIndex >= energies.count)
         break;
      [temp setObject:[energies objectAtIndex:i*fundamentalIndex] atIndexedSubscript:i-1];
   }
   comb = temp;
}

- (unsigned)support
{
   unsigned peaks = 0;
   for (NSNumber * energy in self.comb)
      if (energy.doubleValue > 0.0)
         peaks++;
   return peaks;
}
- (double)supportEnergy
{
   double totalEnergy = 0.0;
   for (NSNumber * energy in self.comb)
      totalEnergy += energy.doubleValue;
   return totalEnergy;
}
- (BOOL) hasMinSupport:(unsigned) minPeaks
{
   return [self support] >= minPeaks;
}

- (BOOL) hasMinEnergy:(double) totalEnergy
{
   return [self supportEnergy] >= totalEnergy;
}
- (BOOL) hasMinimumSupport:(unsigned) minPeaks andEnergy:(double) minTotalEnergy
{
   unsigned peaks = 0;
   double totalEnergy = 0.0;
   for (NSNumber * energy in self.comb) {
      if (energy.doubleValue > 0.0) {
         peaks++;
         totalEnergy += energy.doubleValue;
      }
   }
//   NSLog(@"Counted %u peaks and total energy %f", peaks, totalEnergy);
   return peaks >= minPeaks && totalEnergy >= minTotalEnergy;
}

- (BOOL) isSubharmonicOf:(PSNoteHypothesis *)high
{
   //  Not octave relation with self as lower
   if (high.index % self.index != 0)
      return NO;
   
   //  Compute energies of even vs. odd, low vs. total
   double oddEnergy = 0.0;
   double evenEnergy = 0.0;
   double lowEnergy = 0.0;
   double totalEnergy = 0.0;
   for (int i = 0; i < self.comb.count; i++) {
      NSNumber * energy = (NSNumber *) [self.comb objectAtIndex:i];
      totalEnergy += energy.doubleValue;
      if (i % 2 == 0)
         evenEnergy += energy.doubleValue;
      else
         oddEnergy += energy.doubleValue;
      if (i < self.comb.count / 4)
         lowEnergy += energy.doubleValue;
   }
   if (oddEnergy * 3 < evenEnergy || lowEnergy * 8 < totalEnergy)
      return YES;
   else
      return NO;
}

- (BOOL) isOvertoneOf:(PSNoteHypothesis *)low
{
   //  Not octave relation with self as higher
   if (self.index % low.index != 0)
      return NO;
   
   //  Compute energies of lower fundamentals
   double lowEnergy = 0.0;
   double totalEnergy = 0.0;
   for (int i = 0; i < self.comb.count; i++) {
      NSNumber * energy = (NSNumber *) [self.comb objectAtIndex:i];
      totalEnergy += energy.doubleValue;
      if (i < self.comb.count / 4)
         lowEnergy += energy.doubleValue;
   }
   if (lowEnergy * 1.01 >= totalEnergy)
      return YES;
   else
      return NO;
}

- (NSString *) description {
   return [NSString stringWithFormat:@"Freq: % 5.2f, Index: %3d, Energy: %@",
           fundamental, fundamentalIndex, [energies objectAtIndex:fundamentalIndex]];
}

@end
