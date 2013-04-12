//
//  PSFirstViewController.h
//  PianoScribe
//
//  Created by Wenley Tong on 2/3/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "PSSoundPlayer.h"


@interface PSFirstViewController : UIViewController <CPTPlotDataSource>
{
   PSSoundPlayer * model;
   UILabel * status;
   UILabel * debug;
   UIButton * playButton;
   CPTXYGraph * graph;
   CPTGraphHostingView * plotView;
}

@property (retain) IBOutlet UILabel * status;
@property (retain) IBOutlet UILabel * debug;
@property (retain) IBOutlet UIButton * playButton;
@property (retain) IBOutlet CPTGraphHostingView * plot;

/* Interactions with View */
- (IBAction) recordPressed:(UIButton *)sender;
- (IBAction) playPressed:(UIButton *)sender;

/* Interaction with Model */
- (void)audioPlayerDidFinishPlayingSuccessfully:(BOOL)flag afterTime:(NSTimeInterval) time;

@end
