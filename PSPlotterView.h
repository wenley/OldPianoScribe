//
//  PSPlotterView.h
//  PianoScribe
//
//  Created by Wenley Tong on 14/3/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PSPlotterView : UIView
{
   CGFloat xmin, xmax, ymin, ymax;
}

@property CGFloat xmin, xmax, ymin, ymax;

@end
