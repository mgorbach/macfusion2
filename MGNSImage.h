/*
 *  MGNSImage.h
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 2/5/08.
 *  Copyright 2008 Michael Gorbach. All rights reserved.
 *
 */

@class CIImage;

@interface NSImage (MGNSImage)

- (CIImage*)ciImageRepresentation;
- (NSImage*)imageScaledToSize:(NSSize)size;
- (NSImage*)flippedImage;
@end

@interface CIImage (MGCIImage)
- (CIImage*)ciImageByScalingToSize:(NSSize)targetSize;
- (CIImage*)ciImageByColoringMonochromeWithColor: (NSColor*)color
									   intenisty: (NSNumber*)intensity;
- (NSImage*)nsImageRepresentation;
- (NSImage*)flippedNSImageRepresentation;
- (CIImage*)flippedImage;
@end
