//
//  MGSmoothingImageView.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MGSmoothingImageView.h"


@implementation MGSmoothingImageView
- (void)drawRect:(NSRect)rect 
{
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
	[[self image] drawInRect:rect
					fromRect:NSZeroRect
				   operation:NSCompositeSourceOver
					fraction:1.0];
}
@end
