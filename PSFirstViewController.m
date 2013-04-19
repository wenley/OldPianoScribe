//
//  PSFirstViewController.m
//  PianoScribe
//
//  Created by Wenley Tong on 2/3/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import "PSFirstViewController.h"


@implementation PSFirstViewController

@synthesize status, debug, playButton;
@synthesize plot = plotView;

- (IBAction) recordPressed:(UIButton *)sender
{
    if (!model)
        model = [[PSSoundPlayer alloc] init];
    if (!model.recording) {
        [model startRecording];
        status.text = @"Recording";
        [sender setTitle:@"Pause" forState:UIControlStateNormal];
    }
   else {
      NSTimeInterval elapsed = [model pause];
      NSLog(@"time elapsed: %f", elapsed);
      status.text = @"Stopped Recording";
      [sender setTitle:@"Record" forState:UIControlStateNormal];
      debug.text = [NSString stringWithFormat:@"Time elapsed: %f", elapsed];
      [graph reloadData];
      [self.plot setNeedsDisplay];
   }
}

- (IBAction) playPressed:(UIButton *)sender
{
   if (!model) {
      model = [[PSSoundPlayer alloc] init];
      NSLog(@"Needed to initialize in play");
   }
   if (!model.playing) {
      [model startPlaying];
      status.text = @"Playing";
      [sender setTitle:@"Pause" forState:UIControlStateNormal];
   }
   else {
      NSTimeInterval elapsed = [model pause];
      status.text = @"Stopped Playing";
      [sender setTitle:@"Play" forState:UIControlStateNormal];
      debug.text = [NSString stringWithFormat:@"Time elapsed: %f", elapsed];
   }
}

- (void)audioPlayerDidFinishPlayingSuccessfully:(BOOL)flag afterTime:(NSTimeInterval) time
{
   [playButton setTitle:@"Play" forState:UIControlStateNormal];
   debug.text = [NSString stringWithFormat:@"Time elapsed: %f", time];
   status.text = @"Stopped";
}

/* - - - Plotting Methods - - - */
- (NSUInteger) numberOfRecordsForPlot:(CPTPlot *)plot
{
   return [model numberOfRecords];
}

- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
   double val = idx;
   if (fieldEnum == CPTScatterPlotFieldX) {
      if ([plot.identifier isEqual:@"Fourier"])
//         return nil;
         return [NSNumber numberWithDouble:val * 4];
      else
         return [NSNumber numberWithDouble:val];
   }
   else {
      if ([plot.identifier isEqual: @"Fourier"])
//         return nil;
         return [model fourierRecordAtIndex:idx];
      else
         return [model dataRecordAtIndex:idx];
   }
}

/* - - - ViewController Methods - - - */

- (void)viewDidLoad
{
   [super viewDidLoad];
   if (!model)
      model = [[PSSoundPlayer alloc] init];
   [model setDelegate:self];
   
   graph = [[CPTXYGraph alloc] initWithFrame:self.plot.bounds];
   
   //  Set up view spacing
   graph.hostingView = self.plot;
   graph.paddingLeft = 10.0;
   graph.paddingRight = 10.0;
   graph.paddingTop = 10.0;
   graph.paddingBottom = 10.0;
   
   //  Set up logical axes
   CPTXYPlotSpace * plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
   plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-192) length:CPTDecimalFromFloat(1216)];
   plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(-1) length:CPTDecimalFromFloat(2)];
   
   //  Set up visual axes
   CPTMutableLineStyle * lineStyle = [CPTMutableLineStyle lineStyle];
   lineStyle.lineColor = [CPTColor blackColor];
   lineStyle.lineWidth = 2.0f;
   CPTXYAxisSet * axes = (CPTXYAxisSet *) graph.axisSet;
   axes.xAxis.majorIntervalLength = [NSDecimalNumber decimalNumberWithString:@"256"].decimalValue;
   axes.xAxis.minorTicksPerInterval = 4;
   axes.xAxis.majorTickLineStyle = lineStyle;
   axes.xAxis.minorTickLineStyle = lineStyle;
   axes.xAxis.axisLineStyle = lineStyle;
   axes.xAxis.minorTickLength = 5.0f;
   axes.xAxis.majorTickLength = 7.0f;
   axes.xAxis.labelOffset = 3.0f;

   axes.yAxis.majorIntervalLength = [NSDecimalNumber decimalNumberWithString:@"0.2"].decimalValue;
   axes.yAxis.minorTicksPerInterval = 2;
   axes.yAxis.majorTickLineStyle = lineStyle;
   axes.yAxis.minorTickLineStyle = lineStyle;
   axes.yAxis.axisLineStyle = lineStyle;
   axes.yAxis.minorTickLength = 5.0f;
   axes.yAxis.majorTickLength = 7.0f;
   axes.yAxis.labelOffset = 3.0f;
   
   CPTScatterPlot * dataPlot = [[CPTScatterPlot alloc]
                                   initWithFrame:graph.bounds];
   dataPlot.identifier = @"Raw Data";
   CPTMutableLineStyle * dataPlotLine = [CPTMutableLineStyle lineStyle];
   dataPlotLine.lineWidth = 1.0f;
   dataPlotLine.lineColor = [CPTColor redColor];
   dataPlot.dataLineStyle = dataPlotLine;
   dataPlot.dataSource = self;
   [graph addPlot:dataPlot];
   
   CPTPlotSymbol *greenCirclePlotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
   greenCirclePlotSymbol.fill = [CPTFill fillWithColor:[CPTColor greenColor]];
   greenCirclePlotSymbol.size = CGSizeMake(2.0, 2.0);
   dataPlot.plotSymbol = greenCirclePlotSymbol;
   
   CPTScatterPlot * fourierPlot = [[CPTScatterPlot alloc]
                                    initWithFrame:graph.bounds];
   fourierPlot.identifier = @"Fourier";
   CPTMutableLineStyle * fourierPlotLine = [CPTMutableLineStyle lineStyle];
   fourierPlotLine.lineWidth = 1.0f;
   fourierPlotLine.lineColor = [CPTColor purpleColor];
   fourierPlot.dataLineStyle = fourierPlotLine;
   fourierPlot.dataSource = self;
   [graph addPlot:fourierPlot];
   
   CPTPlotSymbol *blueCirclePlotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
   blueCirclePlotSymbol.fill = [CPTFill fillWithColor:[CPTColor blueColor]];
   blueCirclePlotSymbol.size = CGSizeMake(2.0, 2.0);
   fourierPlot.plotSymbol = blueCirclePlotSymbol;
   
   NSLog(@"Didn't crash!");
   self.plot.hostedGraph = graph;
}

- (void)didReceiveMemoryWarning
{
   [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
