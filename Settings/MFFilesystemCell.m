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

#define NAME_LEFT_PADDING 5.0
#define NAME_DESC_X_PADDING 10

@implementation MFFilesystemCell
- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	MFClientFS* fs = [self representedObject];
	NSString* name = fs.name ? fs.name : @"Unnamed";
	NSString* status = fs.status;
	NSRect r = cellFrame;
	
	NSDictionary* nameAttributes = [NSDictionary dictionaryWithObjectsAndKeys: 
									[NSFont systemFontOfSize:14], NSFontAttributeName, nil];
	NSSize nameSize = [name sizeWithAttributes: nameAttributes];
	
	if ([status isEqualToString: kMFStatusFSFailed])
	{
		[[NSColor colorWithDeviceRed:1 green:0 blue:0 alpha:.4] set];
	}
	else if ([status isEqualToString: kMFStatusFSMounted])
	{
		[[NSColor colorWithDeviceRed:0 green:1 blue:0 alpha:.4] set];
	}
	else if ([status isEqualToString: kMFStatusFSUnmounted])
	{
		[[NSColor colorWithDeviceRed:0 green:0 blue:1.0 alpha:.4] set];
	}
	
	if (status)
	{
		[NSBezierPath fillRect: r];
	}

	NSPoint namePoint = NSMakePoint(cellFrame.origin.x + NAME_LEFT_PADDING, 
									cellFrame.origin.y + cellFrame.size.height/2.0 - nameSize.height/2.0);

	[name drawAtPoint: namePoint withAttributes:nameAttributes];
	
	NSDictionary* descAttributes = [NSDictionary dictionaryWithObjectsAndKeys: 
									[NSFont systemFontOfSize:12], NSFontAttributeName, nil];
	NSSize descSize = [fs.descriptionString sizeWithAttributes:descAttributes];
	NSPoint descPoint = NSMakePoint(namePoint.x + nameSize.width + NAME_DESC_X_PADDING, 
									cellFrame.origin.y + cellFrame.size.height/2.0 - descSize.height/2.0);
	[fs.descriptionString drawAtPoint: descPoint withAttributes:descAttributes];
	
}

@end
