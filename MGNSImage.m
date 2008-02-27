/*
 *  MGNSImage.m
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 2/5/08.
 *  Copyright 2008 Michael Gorbach. All rights reserved.
 *
 */

#import "MGNSImage.h"
#import <QuartzCore/QuartzCore.h>


@implementation NSImage (MGNSImage)
- (CIImage*)ciImageRepresentation
{
	NSData* tiffData = [self TIFFRepresentation];
	NSBitmapImageRep* bitmapRep = [NSBitmapImageRep imageRepWithData: tiffData];
	CIImage* ciImage = [[CIImage alloc] initWithBitmapImageRep: bitmapRep];
	// Transform to get the orientation right
	CIFilter* transformFilter = [CIFilter filterWithName: @"CIAffineTransform"];
	[transformFilter setValue: ciImage forKey:@"inputImage"];
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform translateXBy:0 yBy: [self size].height ];
	[transform scaleXBy: 1 yBy: -1];
	[transformFilter setValue:transform forKey:@"inputTransform"];
	return [transformFilter valueForKey:@"outputImage"];
}

- (NSImage*)imageScaledToSize:(NSSize)size
{
	return [[[self ciImageRepresentation] ciImageByScalingToSize: size] nsImageRepresentation];
}

- (NSImage*)flippedImage
{
	return [[self ciImageRepresentation] flippedNSImageRepresentation];
}

@end

@implementation CIImage (MGCIImage)

static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef  colorSpace, NSColor *color)
{
	NSColor *deviceColor = [color colorUsingColorSpaceName:  
							NSDeviceRGBColorSpace];
	
	float components[4];
	[deviceColor getRed: &components[0] green: &components[1] blue:  
	 &components[2] alpha: &components[3]];
	
	return CGColorCreate (colorSpace, components);
}


- (CIImage*)ciImageByScalingToSize:(NSSize)targetSize
{
	CIFilter* scalingFilter = [CIFilter filterWithName: @"CILanczosScaleTransform"];
	[scalingFilter setValue: self forKey:@"inputImage"];
	[scalingFilter setValue: [NSNumber numberWithFloat: targetSize.height / [self extent].size.height]
					 forKey:@"inputScale"];
	[scalingFilter setValue: [NSNumber numberWithFloat:1.0] forKey:@"inputAspectRatio"];
	CIImage* out = [scalingFilter valueForKey:@"outputImage"];
	return out;
}
	 
- (CIImage*)ciImageByColoringMonochromeWithColor: (NSColor*)color
									 intenisty: (NSNumber*)intensity
{
	CIFilter* coloringFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef cgColor = CGColorCreateFromNSColor(colorSpace, color);
	[coloringFilter setValue: self forKey:@"inputImage"];
	[coloringFilter setValue: intensity forKey:@"inputIntensity"];
	[coloringFilter setValue: [CIColor colorWithCGColor: cgColor] forKey: @"inputColor"];
	CIImage* out  = [coloringFilter valueForKey:@"outputImage"];
	return out;
}

- (CIImage*)flippedImage
{
	CIFilter* transformFilter = [CIFilter filterWithName: @"CIAffineTransform"];
	[transformFilter setValue: self forKey:@"inputImage"];
	NSAffineTransform* transform = [NSAffineTransform transform];
	[transform translateXBy:0 yBy: [self extent].size.height ];
	[transform scaleXBy: 1 yBy: -1];
	[transformFilter setValue:transform forKey:@"inputTransform"];
	return [transformFilter valueForKey:@"outputImage"];
}

- (NSImage*)nsImageRepresentation
{
	NSImage* new = [[NSImage alloc] init];
	[new setFlipped:YES];
	[new setSize: NSSizeFromCGSize( [self extent].size ) ];
	[new lockFocus];
	[self drawAtPoint: NSMakePoint(0, 0) fromRect: NSMakeRect(0, 0, [self extent].size.width, [self extent].size.height)
			operation:NSCompositeSourceOver fraction:1.0];
	[new unlockFocus];
	return new;
}

- (NSImage*)flippedNSImageRepresentation
{
	NSImage* new = [[NSImage alloc] init];
	[new setSize: NSSizeFromCGSize( [self extent].size ) ];
	[new lockFocus];
	[self drawAtPoint: NSMakePoint(0, 0) fromRect: NSMakeRect(0, 0, [self extent].size.width, [self extent].size.height)
			operation:NSCompositeSourceOver fraction:1.0];
	[new unlockFocus];
	return new;
}


@end