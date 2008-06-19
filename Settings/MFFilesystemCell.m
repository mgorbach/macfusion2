//
//  MFFilesystemCell.m
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

#import "MFFilesystemCell.h"
#import "MFClientFS.h"
#import "MFConstants.h"
#import <QuartzCore/QuartzCore.h>
#import "MGNSImage.h"

#define IMAGE_SIZE 48
#define HORIZONTAL_PADDING 10.0f
#define VERTICAL_PADDING 5.0f


@implementation MFFilesystemCell

- (id)init
{
	if (self = [super init])
	{
		self.editPushed = NO;
		self.mountPushed = NO;
		NSPointerFunctionsOptions options = NSPointerFunctionsObjectPointerPersonality;
		icons = [NSMapTable mapTableWithKeyOptions:options valueOptions:options];
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
	return frame;
	NSRect insetRect = NSInsetRect(frame, 10, 0);
	return insetRect;
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

- (NSRect) progressIndicatorRectInRect:(NSRect)rect
{
	NSRect boxRect = [self iconBoxWithFrame: rect];
	NSSize indicatorSize = NSMakeSize(30, 30);
	return NSMakeRect(boxRect.origin.x + boxRect.size.width/2 - indicatorSize.width/2 , boxRect.origin.y + boxRect.size.height/2 - indicatorSize.height/2
					  , indicatorSize.width, indicatorSize.height);
}

# pragma mark Icons and images
- (NSImage*)iconToDraw
{
	MFClientFS* fs = [self representedObject];
	NSImage* iconToDraw = [icons objectForKey: fs];
	if (!iconToDraw)
	{
		NSImage* icon = [[NSImage alloc] initWithContentsOfFile: 
						 fs.imagePath];
		CIImage* ciImageIcon = [icon ciImageRepresentation];
		CIImage* scaledImage = [ciImageIcon ciImageByScalingToSize: NSMakeSize(IMAGE_SIZE, IMAGE_SIZE) ];
		CIImage* coloredImage = [scaledImage ciImageByColoringMonochromeWithColor: [self tintColor]
																		intenisty: [NSNumber numberWithFloat: 0.4] ];
		iconToDraw = [coloredImage nsImageRepresentation];
		[icons setObject: iconToDraw forKey: fs];
	}

	return iconToDraw;
}

- (void)clearImageForFS:(MFClientFS*)fs
{
	[icons removeObjectForKey: fs];
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
													[NSFont systemFontOfSize:12], NSFontAttributeName,
													style, NSParagraphStyleAttributeName,
													nil];
	NSString* mainText = [NSString stringWithFormat: @"%@ (%@)", fs.name, fs.status];
	NSSize mainTextSize = [mainText sizeWithAttributes: mainTextAttributes];
	
	NSString* secondaryText = fs.descriptionString;
	NSSize secondaryTextSize = [secondaryText sizeWithAttributes: secondaryTextAttributes];

	NSRect iconBox = [self iconBoxWithFrame:cellFrame];
		
	float combinedHeight = mainTextSize.height + secondaryTextSize.height + VERTICAL_PADDING;
	NSRect insetRect = [self insetRectWithFrame: cellFrame];
	NSRect textBox = NSMakeRect( iconBox.origin.x + iconBox.size.width + HORIZONTAL_PADDING,
								insetRect.origin.y + insetRect.size.height * .5 - combinedHeight*.5,
								insetRect.size.width - iconSize.width - HORIZONTAL_PADDING - HORIZONTAL_PADDING,
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

	CGFloat iconFract = [fs isWaiting] ? 0.5 : 1;
	NSImage* outputIcon = [controlView isFlipped] ? [[self iconToDraw] flippedImage] : [self iconToDraw];
	[outputIcon drawAtPoint:iconBox.origin fromRect:NSMakeRect(0, 0, IMAGE_SIZE, IMAGE_SIZE) operation:NSCompositeSourceOver fraction:iconFract];
	
	[mainText drawInRect:mainTextBox withAttributes:mainTextAttributes];
	[secondaryText drawInRect:secondaryTextBox withAttributes:secondaryTextAttributes];
}
 
- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
	return NSCellHitContentArea;
}

@synthesize editPushed, mountPushed;
@end
