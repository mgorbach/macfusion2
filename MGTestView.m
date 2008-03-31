//
//  MGTestView.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/30/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MGTestView.h"
#import <stdlib.h>

@implementation MGTestView

- (NSArray*)randomColors
{
	return [NSArray arrayWithObjects: 
			[NSColor blueColor], [NSColor greenColor],
			[NSColor orangeColor], [NSColor yellowColor],
			[NSColor cyanColor], [NSColor redColor],
			nil];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		long rand = random() % 6;
		color = [[self randomColors] objectAtIndex: rand];
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	[color set];
	[NSBezierPath setDefaultLineWidth: 2.0];
	[NSBezierPath strokeRect: rect];
	[NSBezierPath fillRect: rect];
	[super drawRect: rect];
}

@end
