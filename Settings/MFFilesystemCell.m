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

#define IMAGE_SIZE 48

@implementation MFFilesystemCell

static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef  colorSpace, NSColor *color)
{
	NSColor *deviceColor = [color colorUsingColorSpaceName:  
							NSDeviceRGBColorSpace];
	
	float components[4];
	[deviceColor getRed: &components[0] green: &components[1] blue:  
	 &components[2] alpha: &components[3]];
	
	return CGColorCreate (colorSpace, components);
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

- (CIImage*)iconToDraw
{
	MFClientFS* fs = [self representedObject];
	NSImage* icon = [[NSImage alloc] initWithContentsOfFile: 
					 fs.iconPath];
	CIImage* iconCI = [[CIImage alloc] initWithContentsOfURL: [NSURL fileURLWithPath: fs.iconPath]];
	
	// Scale
	CIFilter* scalingFilter = [CIFilter filterWithName: @"CILanczosScaleTransform"];
	[scalingFilter setValue: iconCI forKey:@"inputImage"];
	[scalingFilter setValue: [NSNumber numberWithFloat: IMAGE_SIZE / [icon size].height]
					 forKey:@"inputScale"];
	[scalingFilter setValue: [NSNumber numberWithFloat: 1.0]
					 forKey:@"inputAspectRatio"];
	iconCI = [scalingFilter valueForKey:@"outputImage"];
	
	CIFilter* coloringFilter =  [CIFilter filterWithName: @"CIColorMonochrome"];
	[coloringFilter setDefaults];
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef cgcolor = CGColorCreateFromNSColor( colorSpace, [self tintColor] );
	[coloringFilter setValue: [CIColor colorWithCGColor:cgcolor]
					  forKey: @"inputColor"];
	[coloringFilter setValue:[NSNumber numberWithFloat:0.4] forKey:@"inputIntensity"];
	[coloringFilter setValue: iconCI forKey:@"inputImage"];
	iconCI = [coloringFilter valueForKey:@"outputImage"];
	
	// Transform (Flip)
	CIFilter* transform = [CIFilter filterWithName:@"CIAffineTransform"];
	[transform setValue: iconCI forKey:@"inputImage"];
	NSAffineTransform *affineTransform = [NSAffineTransform transform];
	[affineTransform translateXBy:0 yBy:IMAGE_SIZE];
	[affineTransform scaleXBy:1 yBy:-1];
	[transform setValue:affineTransform forKey:@"inputTransform"];
	iconCI =  [transform valueForKey:@"outputImage"];
	return iconCI;
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
	
	NSRect iconBox = NSMakeRect( insetRect.origin.x,  insetRect.origin.y + insetRect.size.height*.5 - iconSize.height*.5,
								iconSize.width,
								iconSize.height );
	
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
	
	if ([self isHighlighted])
	{
		[mainTextAttributes setValue: [NSColor whiteColor]
							  forKey: NSForegroundColorAttributeName];
		[secondaryTextAttributes setValue: [NSColor whiteColor]
								   forKey: NSForegroundColorAttributeName];
	}
	
	[[NSGraphicsContext currentContext] setImageInterpolation: NSImageInterpolationHigh];
//	[icon drawInRect: iconBox fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	CIImage* outputIcon = [self iconToDraw];
	CIContext* context = [[NSGraphicsContext currentContext] CIContext];
	[context drawImage: outputIcon atPoint:NSPointToCGPoint(iconBox.origin) fromRect:CGRectMake(0, 0, iconSize.width, iconSize.height)];
	
	[mainText drawInRect:mainTextBox withAttributes:mainTextAttributes];
	[secondaryText drawInRect:secondaryTextBox withAttributes:secondaryTextAttributes];
}

@end
