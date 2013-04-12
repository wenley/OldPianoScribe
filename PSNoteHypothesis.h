//
//  PSNoteHypothesis.h
//  PianoScribe
//
//  Created by Wenley Tong on 5/4/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PSNoteHypothesis : NSObject
{
@private NSArray * energies;
@private double fundamental;
@private unsigned fundamentalIndex;
@private NSArray * comb;
}

- (id) initWithFrequency:(double) fundFreq atIndex:(unsigned) fundIdx ofArray:(NSArray *)energyArray;
- (void) findComb:(unsigned) numPeaks;

@property (readonly) double fundamental;
@property (readonly) unsigned index;
@property (readonly) NSArray * comb;

- (BOOL) hasMinimumSupport:(unsigned) minPeaks andEnergy:(double) minTotalEnergy;
- (BOOL) hasMinSupport:(unsigned) minPeaks;
- (BOOL) hasMinEnergy:(double) totalEnergy;

- (BOOL) isSubharmonicOf:(PSNoteHypothesis *)high;
- (BOOL) isOvertoneOf:(PSNoteHypothesis *)low;

@end
