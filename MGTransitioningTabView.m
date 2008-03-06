//
//  MGTransitioningTabView.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/5/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MGTransitioningTabView.h"
#import <QuartzCore/QuartzCore.h>


@implementation MGTransitioningTabView
static void ClearBitmapImageRep(NSBitmapImageRep *bitmap) {
    unsigned char *bitmapData = [bitmap bitmapData];
    if (bitmapData != NULL) {
        // A fast alternative to filling with [NSColor clearColor].
        bzero(bitmapData, [bitmap bytesPerRow] * [bitmap pixelsHigh]);
    }
}


- (void)drawRect:(NSRect)rect
{
	[super drawRect: rect];
	if (animation != nil)
	{
		[transitionFilter setValue: [NSNumber numberWithFloat: [animation currentValue]]
							forKey:@"inputTime"];
		CIImage* outputImage = [transitionFilter valueForKey:@"outputImage"];
		[outputImage drawInRect:imageRect
					   fromRect:NSMakeRect( 0, imageRect.size.height, imageRect.size.width, -imageRect.size.height )
					  operation:NSCompositeSourceOver
					   fraction:1.0];
		 
	}
}

- (void)setTransitionForinitialCIImage:(CIImage *)initialCIImage 
					   finalCIImage:(CIImage *)finalCIImage
{
	transitionFilter = [CIFilter filterWithName:@"CIDissolveTransition"];
	[transitionFilter setDefaults];
	[transitionFilter setValue:initialCIImage forKey:@"inputImage"];
	[transitionFilter setValue:finalCIImage forKey:@"inputTargetImage"];
}

- (void)selectTabViewItem:(NSTabViewItem*)tabViewItem
{
	if ([self selectedTabViewItem] == nil || [self isHiddenOrHasHiddenAncestor])
	{
		[super selectTabViewItem: tabViewItem];
		return;
	}
		
		
	NSView* initialView = [[self selectedTabViewItem] view];
	NSView* finalView = [tabViewItem view];
	NSRect rect = NSUnionRect([initialView bounds], [finalView bounds]);
	imageRect = NSUnionRect([initialView frame], [finalView frame]);
	
	// MFLogS(self, @"imageRect %@ rect %@", NSStringFromRect( imageRect ), NSStringFromRect( rect) );
	NSBitmapImageRep* initialContentBitmap = [initialView bitmapImageRepForCachingDisplayInRect:rect];
	ClearBitmapImageRep(initialContentBitmap);
	[initialView cacheDisplayInRect:rect toBitmapImageRep:initialContentBitmap];
	
	[super selectTabViewItem: tabViewItem];
	NSBitmapImageRep* finalContentBitmap = [finalView bitmapImageRepForCachingDisplayInRect:rect];
	ClearBitmapImageRep(finalContentBitmap);
	[finalView cacheDisplayInRect:rect toBitmapImageRep:finalContentBitmap];
	
	CIImage* initialCIImage = [[CIImage alloc] initWithBitmapImageRep:initialContentBitmap];
	CIImage* finalCIImage = [[CIImage alloc] initWithBitmapImageRep:finalContentBitmap];
	[self setTransitionForinitialCIImage:initialCIImage finalCIImage:finalCIImage];
	
	animation = [[TabViewAnimation alloc] initWithDuration: .5 animationCurve:NSAnimationEaseInOut];
	[animation setDelegate: self];
	[finalView setHidden: YES];
	[animation startAnimation];
	[finalView setHidden: NO];
	animation = nil;
}
@end

@implementation TabViewAnimation

// Override NSAnimation's -setCurrentProgress: method, and use it as our point to hook in and advance our Core Image transition effect to the next time slice.
- (void)setCurrentProgress:(NSAnimationProgress)progress {
    [super setCurrentProgress:progress];
    [[self delegate] display];
}

@end
