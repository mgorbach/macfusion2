//
//  MFFilesystemCell.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/17/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFFilesystemCell.h"
#import "MFClientFS.h"
#import "MFConstants.h"
#import <QuartzCore/QuartzCore.h>
#import "MGNSImage.h"

#define IMAGE_SIZE 48

@implementation MFFilesystemCell

- (NSColor*)tintColor
{
	MFClientFS* fs = [self representedObject];
	if ([fs isMounted])
		return [NSColor greenColor];
	if ([fs isFailedToMount])
		return [NSColor redColor];
	if ([fs isWaiting])
		return [NSColor yellowColor];
	if ([fs isUnmounted])
		return [NSColor grayColor];
	
	return nil;
}

- (NSImage*)iconToDraw
{
	MFClientFS* fs = [self representedObject];
	
	NSImage* icon = [[NSImage alloc] initWithContentsOfFile: 
					 fs.iconPath];
	CIImage* ciImageIcon = [icon ciImageRepresentation];
	CIImage* scaledImage = [ciImageIcon ciImageByScalingToSize: NSMakeSize(IMAGE_SIZE, IMAGE_SIZE) ];
	CIImage* coloredImage = [scaledImage ciImageByColoringMonochromeWithColor: [self tintColor]
																	intenisty: [NSNumber numberWithFloat: 0.4] ];

	return [coloredImage nsImageRepresentation];
//	return [icon imageScaledToSize: NSMakeSize(IMAGE_SIZE, IMAGE_SIZE)];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{	
	MFClientFS* fs = [self representedObject];
	NSRect insetRect = NSInsetRect(cellFrame, 10, 0);
	NSSize iconSize = NSMakeSize(IMAGE_SIZE, IMAGE_SIZE);
	NSMutableParagraphStyle* style = [NSMutableParagraphStyle new];
	[style setLineBreakMode: NSLineBreakByTruncatingTail];
	
	NSMutableDictionary* mainTextAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
											   [NSColor blackColor], NSForegroundColorAttributeName,
											   [NSFont systemFontOfSize:14], NSFontAttributeName,
											   style, NSParagraphStyleAttributeName,
											   nil];
	NSMutableDictionary* secondaryTextAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
													[NSColor grayColor], NSForegroundColorAttributeName,
													[NSFont systemFontOfSize:14], NSFontAttributeName,
													style, NSParagraphStyleAttributeName,
													nil];
	NSString* mainText = [NSString stringWithFormat: @"%@ (%@)", fs.name, fs.status];
	NSSize mainTextSize = [mainText sizeWithAttributes: mainTextAttributes];
	
	NSString* secondaryText = fs.descriptionString;
	NSSize secondaryTextSize = [secondaryText sizeWithAttributes: secondaryTextAttributes];
	
	float verticalPadding = 5.0;
	float horizontalPadding = 10.0;
	NSSize buttonSize = NSMakeSize(65, 20);
	NSSize totalButtonSize = NSMakeSize(2*buttonSize.width + horizontalPadding, buttonSize.height);
	
	NSRect iconBox = NSMakeRect( insetRect.origin.x,  insetRect.origin.y + insetRect.size.height*.5 - iconSize.height*.5,
								iconSize.width,
								iconSize.height );
	
	NSRect buttonBox = NSMakeRect(insetRect.origin.x + insetRect.size.width - totalButtonSize.width,
								   insetRect.origin.y + insetRect.size.height * 0.5 - totalButtonSize.height * .5,
								   totalButtonSize.width,
								   totalButtonSize.height);
	NSRect editButtonBox = NSMakeRect(buttonBox.origin.x, buttonBox.origin.y, buttonSize.width, buttonSize.height);
	NSRect mountButtonBox = NSMakeRect(editButtonBox.origin.x + buttonSize.width + horizontalPadding,
										buttonBox.origin.y, buttonSize.width, buttonSize.height);
	
	NSBezierPath* mountButtonPath = [NSBezierPath bezierPathWithRoundedRect:mountButtonBox
																	xRadius:10 yRadius:10];
	NSBezierPath* editButtonPath = [NSBezierPath bezierPathWithRoundedRect:editButtonBox
																   xRadius:10
																   yRadius:10];
	
	float combinedHeight = mainTextSize.height + secondaryTextSize.height + verticalPadding;
	NSRect textBox = NSMakeRect( iconBox.origin.x + iconBox.size.width + horizontalPadding,
								insetRect.origin.y + insetRect.size.height * .5 - combinedHeight*.5,
								insetRect.size.width - iconSize.width - horizontalPadding,
								combinedHeight );
	NSRect mainTextBox = NSMakeRect( textBox.origin.x,
								 textBox.origin.y + textBox.size.height*.5 - mainTextSize.height,
								 textBox.size.width ,
								 mainTextSize.height );
	NSRect secondaryTextBox = NSMakeRect(textBox.origin.x,
										 textBox.origin.y + textBox.size.height*.5,
										 textBox.size.width,
										 secondaryTextSize.height);
	
	
	NSMutableDictionary* buttonTextAttributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										  [NSColor blackColor], NSForegroundColorAttributeName,
										  [NSFont systemFontOfSize:13], NSFontAttributeName,
										  nil];
	
	// Edit button
	if (![fs isMounted])
	{
		NSString* editText = @"Edit";
		NSSize editSize = [editText sizeWithAttributes:buttonTextAttributes];
		NSRect editTextRect = NSMakeRect(editButtonBox.origin.x + editButtonBox.size.width*0.5 - editSize.width*0.5,
										 editButtonBox.origin.y + editButtonBox.size.height*0.5 - editSize.height*0.5,
										 editSize.width,
										 editSize.height);
		[[NSColor lightGrayColor] set];
		[editButtonPath fill];
		[editText drawInRect: editTextRect withAttributes:buttonTextAttributes];
	}
	
	// Mount Button
	if (![fs isWaiting])
	{
		NSString* mountText = [fs isMounted] ? @"Unmount" : @"Mount";
		NSFont* font = [fs isMounted] ? [NSFont systemFontOfSize:12] : [NSFont systemFontOfSize:13];
		[buttonTextAttributes setObject: font forKey:NSFontAttributeName];
		NSSize mountSize = [mountText sizeWithAttributes:buttonTextAttributes];
		NSRect mountTextRect = NSMakeRect(mountButtonBox.origin.x + mountButtonBox.size.width*0.5 - mountSize.width*0.5,
										 mountButtonBox.origin.y + mountButtonBox.size.height*0.5 - mountSize.height*0.5,
										 mountSize.width,
										 mountSize.height);
		[NSGraphicsContext saveGraphicsState];
		[[NSColor lightGrayColor] set];
		[mountButtonPath fill];
		[NSGraphicsContext restoreGraphicsState];
		[mountText drawInRect: mountTextRect withAttributes:buttonTextAttributes];
	}
	
	if ([self isHighlighted])
	{
		[mainTextAttributes setValue: [NSColor whiteColor]
							  forKey: NSForegroundColorAttributeName];
		[secondaryTextAttributes setValue: [NSColor whiteColor]
								   forKey: NSForegroundColorAttributeName];
	}
	
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];

	NSImage* outputIcon = [controlView isFlipped] ? [[self iconToDraw] flippedImage] : [self iconToDraw];
	[outputIcon drawAtPoint:iconBox.origin fromRect:NSMakeRect(0, 0, IMAGE_SIZE, IMAGE_SIZE) operation:NSCompositeSourceOver fraction:1.0];
	
	[mainText drawInRect:mainTextBox withAttributes:mainTextAttributes];
	[secondaryText drawInRect:secondaryTextBox withAttributes:secondaryTextAttributes];
}

@end
