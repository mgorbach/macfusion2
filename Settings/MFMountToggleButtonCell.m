//
//  MFMountToggleButtonCell.m
//  MacFusion2
//
//  Created by Michael Gorbach on 6/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MFMountToggleButtonCell.h"
#import "MFClientFS.h"

@implementation MFMountToggleButtonCell

- (BOOL)isEnabled
{
	if (![[self representedObject] isWaiting])
		return YES;
	else
		return NO;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	MFClientFS* fs = (MFClientFS*)[self representedObject];
	if ([fs isUnmounted])
	{
		[self setTitle: @"Mount"];
	}
	else if ([fs isMounted])
	{
		[self setTitle: @"Unmount"];
	}
	
	[super drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
