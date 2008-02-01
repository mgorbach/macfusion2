//
//  MFFSItemView.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/27/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFFSItemView.h"


@implementation MFFSItemView

- (void)drawRect:(NSRect)rect
{
	NSRect r = [self bounds];
	NSColor* color;
	if (YES)
	{
		color = [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:.4];
	}
	else
	{
		color = [NSColor colorWithCalibratedRed:0 green:1 blue:0 alpha:.4];
	}

	
	[color set];
	[NSBezierPath fillRect: r];
}

@end
