//
//  MGFadingWindow.m
//  MacFusion2
//
//  Created by Michael Gorbach on 2/27/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MGFadingWindow.h"
#import <QuartzCore/QuartzCore.h>

@implementation MGFadingWindow
- (id) init
{
	self = [super init];
	if (self != nil) {
		closing = NO;
	}
	return self;
}

- (void)animationDidStop:(CAAnimation*)animation finished:(BOOL)finished
{
	if (closing)
	{
		[super orderWindow: NSWindowOut relativeTo:0];
	}
}

- (void)orderWindow:(NSWindowOrderingMode)orderingMode relativeTo:(NSInteger)otherWindowNumber
{
	if (orderingMode == NSWindowAbove && !([self isVisible]))
	{
		closing = NO;
		[self setAlphaValue: 0];
		[super orderWindow:orderingMode relativeTo:otherWindowNumber];
		[[self animator] setAlphaValue: 1];
	}
	else if (orderingMode == NSWindowOut)
	{	
		closing = YES;
		CABasicAnimation* anim = [self animationForKey:@"alphaValue"];
		[anim setDelegate:self];
		[self setAnimations: [NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
		[[self animator] setAlphaValue:0];
	}
	else
	{
		[super orderWindow:orderingMode relativeTo:otherWindowNumber];
	}
}

@end
