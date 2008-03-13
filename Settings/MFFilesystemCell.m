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
#define HORIZONTAL_PADDING 10.0f
#define VERTICAL_PADDING 5.0f
#define BUTTON_SIZE NSMakeSize(70, 20)


@implementation MFFilesystemCell

- (id)init
{
	if (self = [super init])
	{
		self.editPushed = NO;
		self.mountPushed = NO;
	}
	
	return self;
}

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

# pragma mark Geometry

- (NSRect)insetRectWithFrame:(NSRect)frame
{
	NSRect insetRect = NSInsetRect(frame, 10, 0);
	return insetRect;
}

- (NSRect)buttonBoxWithFrame:(NSRect)frame
{
	NSRect insetRect = [self insetRectWithFrame: frame];
	NSSize totalButtonSize = NSMakeSize(2*BUTTON_SIZE.width + HORIZONTAL_PADDING, BUTTON_SIZE.height);
	NSRect buttonBox = NSMakeRect(insetRect.origin.x + insetRect.size.width - totalButtonSize.width,
								  insetRect.origin.y + insetRect.size.height * 0.5 - totalButtonSize.height * .5,
								  totalButtonSize.width,
								  totalButtonSize.height);
	return buttonBox;
}


- (NSRect)editButtonBoxWithFrame:(NSRect)frame
{
	NSRect buttonBox = [self buttonBoxWithFrame: frame];
	NSRect editButtonBox = NSMakeRect(buttonBox.origin.x, buttonBox.origin.y, BUTTON_SIZE.width, BUTTON_SIZE.height);
	return editButtonBox;
}

- (NSRect)mountButtonBoxWithFrame:(NSRect)frame
{
	NSRect buttonBox = [self buttonBoxWithFrame: frame];
	NSRect editButtonBox = [self editButtonBoxWithFrame: frame];
	NSRect mountButtonBox = NSMakeRect(editButtonBox.origin.x + BUTTON_SIZE.width + HORIZONTAL_PADDING,
									   buttonBox.origin.y, BUTTON_SIZE.width, BUTTON_SIZE.height);
	return mountButtonBox;
}

- (NSRect)iconBoxWithFrame:(NSRect)frame
{
	NSRect insetRect = [self insetRectWithFrame: frame];
	NSSize iconSize = NSMakeSize(IMAGE_SIZE, IMAGE_SIZE);
	NSRect iconBox = NSMakeRect( insetRect.origin.x,  insetRect.origin.y + insetRect.size.height*.5 - iconSize.height*.5,
								iconSize.width,
								iconSize.height );
	return iconBox;
}

# pragma mark Icons and images
- (NSImage*)iconToDraw
{
	MFClientFS* fs = [self representedObject];
	
	NSImage* icon = [[NSImage alloc] initWithContentsOfFile: 
					 fs.imagePath];
	CIImage* ciImageIcon = [icon ciImageRepresentation];
	CIImage* scaledImage = [ciImageIcon ciImageByScalingToSize: NSMakeSize(IMAGE_SIZE, IMAGE_SIZE) ];
	CIImage* coloredImage = [scaledImage ciImageByColoringMonochromeWithColor: [self tintColor]
																	intenisty: [NSNumber numberWithFloat: 0.4] ];

	return [coloredImage nsImageRepresentation];
}

# pragma mark Enabling
- (BOOL)mountButtonEnabled
{
	MFClientFS* fs = [self representedObject];
	return ([fs isUnmounted] || [fs isFailedToMount] || [fs isMounted]);
}

- (BOOL)editButtonEnabled
{
	MFClientFS* fs = [self representedObject];
	return ([fs isUnmounted] || [fs isFailedToMount]);
}

# pragma mark Drawing
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{	
	MFClientFS* fs = [self representedObject];

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

	NSRect iconBox = [self iconBoxWithFrame:cellFrame];
	NSRect editButtonBox = [self editButtonBoxWithFrame:cellFrame];
	NSRect mountButtonBox = [self mountButtonBoxWithFrame:cellFrame];
		
	float combinedHeight = mainTextSize.height + secondaryTextSize.height + VERTICAL_PADDING;
	NSRect insetRect = [self insetRectWithFrame: cellFrame];
	NSRect textBox = NSMakeRect( iconBox.origin.x + iconBox.size.width + HORIZONTAL_PADDING,
								insetRect.origin.y + insetRect.size.height * .5 - combinedHeight*.5,
								insetRect.size.width - iconSize.width - HORIZONTAL_PADDING - editButtonBox.size.width - mountButtonBox.size.width - 2*HORIZONTAL_PADDING,
								combinedHeight );

	NSRect mainTextBox = NSMakeRect( textBox.origin.x,
								 textBox.origin.y + textBox.size.height*.5 - mainTextSize.height,
								 textBox.size.width ,
								 mainTextSize.height );
	NSRect secondaryTextBox = NSMakeRect(textBox.origin.x,
										 textBox.origin.y + textBox.size.height*.5,
										 textBox.size.width,
										 secondaryTextSize.height);
	
	
	BOOL current = ([[controlView window] firstResponder] == controlView && 
					[[controlView window] isKeyWindow]);
	
	if (![controlView inLiveResize])
	{
		// Edit button
		
		NSString* editText = @"Edit";
		NSButtonCell* button = [[NSButtonCell alloc] initTextCell: editText];
		[button setBezelStyle: NSRoundRectBezelStyle];
		[button setGradientType: NSGradientConcaveWeak];
		if (editPushed)
			[button highlight:YES withFrame: editButtonBox inView:controlView];
		if (! [self editButtonEnabled] )
			[button setEnabled: NO];
		[button drawBezelWithFrame: editButtonBox inView: controlView];
		[button drawInteriorWithFrame: editButtonBox inView: controlView];
		
		// Mount Button
		NSString* mountText = [fs isMounted] ? @"Unmount" : @"Mount";
		button = [[NSButtonCell alloc] initTextCell: mountText];
		[button setBezelStyle: NSRoundRectBezelStyle];
		[button setGradientType: NSGradientConcaveWeak];
		[button setState: NSOnState];
		if (mountPushed)
			[button highlight:YES withFrame: mountButtonBox inView:controlView];
		if (! [self mountButtonEnabled] )
			[button setEnabled: NO];
		[button drawBezelWithFrame: mountButtonBox inView: controlView];
		[button drawInteriorWithFrame: mountButtonBox inView: controlView];
	}

	

	if ([self isHighlighted] && current)
	{
		[mainTextAttributes setValue: [NSColor whiteColor]
							  forKey: NSForegroundColorAttributeName];
		[secondaryTextAttributes setValue: [NSColor whiteColor]
								   forKey: NSForegroundColorAttributeName];
	}
	if ([self isHighlighted] && !current)
	{
		[mainTextAttributes setValue: [NSColor whiteColor]
							  forKey: NSForegroundColorAttributeName];
		[secondaryTextAttributes setValue: [NSColor whiteColor]
								   forKey: NSForegroundColorAttributeName];
	}

	NSImage* outputIcon = [controlView isFlipped] ? [[self iconToDraw] flippedImage] : [self iconToDraw];
	[outputIcon drawAtPoint:iconBox.origin fromRect:NSMakeRect(0, 0, IMAGE_SIZE, IMAGE_SIZE) operation:NSCompositeSourceOver fraction:1.0];
	
	[mainText drawInRect:mainTextBox withAttributes:mainTextAttributes];
	[secondaryText drawInRect:secondaryTextBox withAttributes:secondaryTextAttributes];
}

# pragma mark Tracking
- (void) addTrackingAreasForView: (NSView *) controlView inRect: (NSRect) cellFrame withUserInfo: (NSDictionary *) userInfo
				   mouseLocation: (NSPoint) mouseLocation
{
	NSTrackingAreaOptions options = NSTrackingEnabledDuringMouseDrag | NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways;
	NSRect mountButtonBox = [self mountButtonBoxWithFrame: cellFrame];
	NSRect editButtonBox = [self editButtonBoxWithFrame: cellFrame];
	NSMutableDictionary* mountTrackingDict = [NSMutableDictionary dictionaryWithObject:@"Mount" forKey:@"Type"];
	NSMutableDictionary* editTrackingDict = [NSMutableDictionary dictionaryWithObject:@"Edit" forKey:@"Type"];
	[mountTrackingDict addEntriesFromDictionary: userInfo];
	[editTrackingDict addEntriesFromDictionary: userInfo];
		
	NSTrackingArea* mountTrackingArea = [[NSTrackingArea alloc] initWithRect:mountButtonBox
																	 options:options 
																	   owner:controlView 
																	userInfo:mountTrackingDict];
	[controlView addTrackingArea: mountTrackingArea];
	NSTrackingArea* editTrackingArea = [[NSTrackingArea alloc] initWithRect:editButtonBox
																	 options:options 
																	   owner:controlView 
																	userInfo:editTrackingDict];
	[controlView addTrackingArea: editTrackingArea];
}


- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
	return NSCellHitContentArea;
}
 

@synthesize editPushed, mountPushed;
@end
