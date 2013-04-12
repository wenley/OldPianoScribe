//
//  PSPlotterView.m
//  PianoScribe
//
//  Created by Wenley Tong on 14/3/13.
//  Copyright (c) 2013 Wenley Tong. All rights reserved.
//

#import "PSPlotterView.h"

@implementation PSPlotterView

@synthesize xmin, xmax, ymin, ymax;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
       self.xmax = self.bounds.size.width / 2;
       self.xmin = -self.xmax;
       self.ymax = self.bounds.size.height / 2;
       self.ymin = -self.ymax;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
   CGContextRef context = UIGraphicsGetCurrentContext();
   CGPoint center;
   center.x = self.bounds.origin.x + self.bounds.size.width / 2;
   center.y = self.bounds.origin.y + self.bounds.size.height / 2;
   
   //  Draw x-axis
   CGContextMoveToPoint(context, self.bounds.origin.x, center.y);
   CGContextAddLineToPoint(context, self.bounds.origin.x + self.bounds.size.width, center.y);
   CGContextStrokePath(context);
   
   //  Draw y-axis
   CGContextMoveToPoint(context, center.x, self.bounds.origin.y);
   CGContextAddLineToPoint(context, center.x, self.bounds.origin.y + self.bounds.size.height);
   CGContextStrokePath(context);
}

- (void)setXrangeFrom:(float)min to:(float)max
{
   self.xmin = min;
   self.xmax = max;
}
- (void)setYrangeFrom:(float)min to:(float)max
{
   self.ymin = min;
   self.ymax = max;
}
- (void)clearGraph
{
   
}

@end
