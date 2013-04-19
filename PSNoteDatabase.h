//
//  PSNoteDatabase.h
//  PianoScribe
//
//  Created by Wenley Tong on 8/4/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>

enum { NUM_NOTES = 5 };
enum { WINDOW_SIZE = 60 };

@interface PSNoteDatabase : NSObject
{
   NSArray * notes;
}

- (id) initFromDirectory:(NSString *)noteDirectory;
- (NSArray *) bestHypothesisForSignal:(NSArray *) signal;


@end
