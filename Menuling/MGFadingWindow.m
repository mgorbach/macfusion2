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

- (void)setVisible:(BOOL)visible
{
	closing = NO;
	[self setAlphaValue: 0];
	[super display];
	//	CABasicAnimation* anim = [self animationForKey:@"alphaValue"];
	//	[anim setDelegate:self];
	//	[self setAnimations: [NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
	[[self animator] setAlphaValue:1];
}


- (void)close
{
	closing = YES;
	CABasicAnimation* anim = [self animationForKey:@"alphaValue"];
	[anim setDelegate:self];
	[self setAnimations: [NSDictionary dictionaryWithObject:anim forKey:@"alphaValue"]];
	[[self animator] setAlphaValue:0];
}

- (void)animationDidStop:(CAAnimation*)animation finished:(BOOL)finished
{
	if (closing)
	{
		[self setAlphaValue: 1];
		[super close];
	}
}

@end
