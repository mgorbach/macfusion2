//
//  TestView.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/26/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "TestView.h"


@implementation TestView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	[[NSColor cyanColor] set];
	[NSBezierPath setDefaultLineWidth: 2.0];
	[NSBezierPath strokeRect: rect];
	[super drawRect: rect];
}

@end
