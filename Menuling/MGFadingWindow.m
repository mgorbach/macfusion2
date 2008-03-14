//
//  MGFadingWindow.m
//  MacFusion2
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
/*
- (void)keyDown:(NSEvent*)event
{
	if ([event keyCode] == 53)
	{
		[self close];
	}
	else
	{
		[super keyDown:event];
	}
}
 */

@end
