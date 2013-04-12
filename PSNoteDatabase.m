//
//  PSNoteDatabase.m
//  PianoScribe
//
//  Created by Wenley Tong on 8/4/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import "PSNoteDatabase.h"

@interface PSNoteDatabase()

- (NSArray *) alignDatabaseToSignal:(NSArray *) signal;
- (int) maxConvolutionOfSignal:(NSArray *)signal1 withSignal:(NSArray *)signal2;
- (void) computeInverseOf:(double *) array withRows:(int) rows andColumns:(int) cols into:(double *) result;

@end

@implementation PSNoteDatabase

- (id) initFromDirectory:(NSString *)noteDirectory
{
   self = [super init];
   if (self) {
      NSMutableArray * temp = [[NSMutableArray alloc] initWithCapacity:88];
      NSArray * directory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:noteDirectory error:NULL];
      if (directory.count == 0)
         NSLog(@"Empty directory? %@", noteDirectory);
      for (int i = 0; i < directory.count; i++) {
         NSLog(@"Object type is %@", [[directory objectAtIndex:i] class]);
         NSString * contents = [NSString stringWithContentsOfFile:[directory objectAtIndex:i] encoding:NSASCIIStringEncoding error:NULL];
         NSArray * lines = [contents componentsSeparatedByString:@"\n"];
         int index = ((NSString *) [lines objectAtIndex:0]).intValue;
         if (index < 0 || index >= NUM_NOTES) {
            NSLog(@"Bad note index: %@", [directory objectAtIndex:i]);
            continue;
         }
         if (lines.count - 1 != WINDOW_SIZE) {
            NSLog(@"Bad window size: %@", [directory objectAtIndex:i]);
            continue;
         }
         NSMutableArray * window = [NSMutableArray arrayWithCapacity:WINDOW_SIZE];
         for (int i = 1; i < lines.count; i++) {
            int value = ((NSString *) [lines objectAtIndex:i]).intValue;
            [window insertObject:[NSNumber numberWithInt:value] atIndex:i-1];
         }
         [temp insertObject:window atIndex:index];
      }
      notes = temp;
   }
   return self;
}

- (NSArray *) alignDatabaseToSignal:(NSArray *) signal
{
   NSMutableArray * alignedNotes = [NSMutableArray arrayWithCapacity:notes.count];
   for (int i = 0; i < notes.count; i++) {
      NSArray * note = [notes objectAtIndex:i];
      if (signal.count != note.count) {
         NSLog(@"Mismatch in signal lengths: signal %d, while database %d", signal.count, note.count);
         return nil;
      }
      int maxt = [self maxConvolutionOfSignal:signal withSignal:note];
      NSMutableArray * alignedNote = [NSMutableArray arrayWithCapacity:note.count];
      for (int n = 0; n < note.count; n++) {
         int index = (n - maxt + note.count) % note.count;
         [alignedNote insertObject:[note objectAtIndex:index] atIndex:n];
      }
      [alignedNotes insertObject:alignedNote atIndex:i];
   }
   return alignedNotes;
}

- (NSArray *) bestHypothesisForSignal:(NSArray *) signal;
{
   NSArray * alignedNotes = [self alignDatabaseToSignal:signal];
   
   //  Make D, D^T, s
   int rows, columns;
   double * D = [self maxtrixFromArray:alignedNotes withDimensions:&rows by:&columns];
   double * DT = calloc(rows * columns, sizeof(double));
   vDSP_mtransD(D, 1, DT, 1, columns, rows);
   double * sig = calloc(signal.count, sizeof(double));
   int i = 0;
   for (NSNumber * value in signal)
      sig[i++] = value.doubleValue;
   
   double * temp = calloc(rows * rows, sizeof(double));
   vDSP_mmulD(D, 1, DT, 1, temp, 1, rows, rows, columns);
   double * inv = calloc(rows * rows, sizeof(double));
   [self computeInverseOf:temp withRows:rows andColumns:rows into:inv];
   double * transform = calloc(rows * columns, sizeof(double));
   vDSP_mmulD(inv, 1, D, 1, transform, 1, rows, columns, rows);
   
   double * alpha = calloc(rows, sizeof(double));
   vDSP_mmulD(transform, 1, sig, 1, alpha, 1, rows, 1, columns);
   
   return nil;
}

- (int) maxConvolutionOfSignal:(NSArray *)signal1 withSignal:(NSArray *)signal2
{
   if (signal1.count != signal2.count)
      return -1;
   double * signal = calloc(signal1.count, sizeof(double));
   double * filter = calloc(signal2.count, sizeof(double));
   int i = 0;
   for (NSNumber * x in signal1)
      signal[i++] = x.doubleValue;
   i = 0;
   for (NSNumber * x in signal2)
      filter[i++] = x.doubleValue;
   double * result = calloc(signal1.count, sizeof(double));
   vDSP_convD(signal, 1, filter + signal2.count, -1, result, 1, signal1.count, signal2.count);
   
   //  Find t that gives max value
   int maxt = 0;
   double maxVal = 0.0;
   for (int i = 0; i < signal1.count; i++) {
      double absVal = fabs(result[i]);
      if (absVal > maxVal) {
         maxt = i;
         maxVal = absVal;
      }
   }
   
   free(signal);
   free(filter);
   return maxt;
}

- (void) computeInverseOf:(double *) array withRows:(int) rows andColumns:(int) cols into:(double *) result
{
   //  Copy to avoid modifying array during Gauss-Jordan
   //  Also create 2D version of result
   double ** matrix = calloc(rows, sizeof(double *));
   double ** result2D = calloc(rows, sizeof(double *));
   for (int i = 0; i < rows; i++) {
      matrix[i] = calloc(cols, sizeof(double));
      for (int j = 0; j < cols; j++)
         matrix[i][j] = array[i*cols + j];
      result2D[i] = calloc(cols, sizeof(double));
      result2D[i][i] = 1.0;
   }
   
   //  Gauss-Jordan Elimination
   //  From pseudo-code on Wikipedia
   for (int k = 0; k < rows; k++) {
      //  Find pivot row
      int i_max = k;
      for (int i = k + 1; i < rows; i++)
         if (fabs(matrix[i][k]) > fabs(matrix[i_max][k]))
            i_max = i;
      if (matrix[i_max][k] == 0.0)
         NSLog(@"Failed; can't find inverse");
      //  Swap if necessary
      if (i_max != k) {
         double * temp = matrix[i_max];
         matrix[i_max] = matrix[k];
         matrix[k] = temp;
         
         temp = result2D[i_max];
         result2D[i_max] = result2D[k];
         result2D[k] = temp;
      }
      //  Perform row operation
      for (int i = k + 1; i < rows; i++) {
         double factor = matrix[i][k] / matrix[k][k];
         for (int j = k + 1; j < cols; j++) {
            matrix[i][j] = matrix[i][j] - matrix[k][j] * factor;
            result2D[i][j] = result2D[i][j] - result2D[k][j] * factor; //  Perform parallel computation
         }
         matrix[i][k] = 0.0;
      }
   }

   //  Clean up and write down results
   for (int i = 0; i < rows; i++)
      free(matrix[i]);
   free(matrix);
   for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++)
         result[i*cols + j] = result2D[i][j];
      free(result2D[i]);
   }
   free(result2D);
}

- (double *) maxtrixFromArray:(NSArray *)array withDimensions:(int *)rows by:(int *)columns;
{
   *rows = array.count;
   *columns = -1;
   double * matrix = calloc(*rows * *columns, sizeof(double));

   for (int i = 0; i < array.count; i++) {
      NSArray * row = [array objectAtIndex:i];
      if (*columns == -1)
         *columns = row.count;
      else if (row.count != *columns) {
         NSLog(@"Rows not of same length! Row %d is of length %d, vs. %d", i, row.count, *columns);
         free(matrix);
         *rows = -1;
         *columns = -1;
         return NULL;
      }
      for (int j = 0; j < row.count; j++) {
         NSNumber * value = [row objectAtIndex:j];
         matrix[i*array.count + j] = value.doubleValue;
      }
   }
   return matrix;
}

@end
