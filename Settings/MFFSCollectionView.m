//
//  MFFSCollectionView.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/27/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFFSCollectionView.h"


@implementation MFFSCollectionView
- (void)mouseDown:(NSEvent*)theEvent
{
	NSLog(@"MD");
//	[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];
	[super mouseDown: theEvent];
}

- (void)rightMouseDown:(NSEvent*)theEvent
{
	NSLog(@"RMD");
	[NSMenu popUpContextMenu:[self menu] withEvent:theEvent forView:self];
}

@end
