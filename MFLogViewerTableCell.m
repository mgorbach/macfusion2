//
//  MFLogViewerTableCell.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/24/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
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

#import "MFLogViewerTableCell.h"
#import "MFLogReader.h"
#import <math.h>
#import "MFLogging.h"
#import "MFClient.h"


#define Y_PADDING = 5.0;

@interface MFLogViewerTableCell(PrivateAPI)
- (NSDictionary*)textAttributesWithControlView:(NSView*)view;
- (NSDictionary*)headerAttributesWithControlView:(NSView*)controlView;

- (NSAttributedString*)headerForMessage:(NSDictionary*)messageDict
							controlView:(NSView*)controlView;
- (NSAttributedString*)textForMessage:(NSDictionary*)messageDict 
						  controlView:(NSView*)controlView;
@end

@implementation MFLogViewerTableCell

- (id)init
{
	if (self = [super init])
	{
		[NSDateFormatter setDefaultFormatterBehavior: NSDateFormatterBehavior10_4];
		formatter = [NSDateFormatter new];
		[formatter  setDateStyle:NSDateFormatterShortStyle];
		[formatter setTimeStyle: NSDateFormatterShortStyle];
		heightCache = [NSMapTable mapTableWithStrongToStrongObjects];
	}
	
	return self;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	if (![controlView inLiveResize])
	{
		NSDictionary* messageDict = [self representedObject];
		NSAttributedString* headerText = [self headerForMessage: messageDict
													controlView: controlView];
		NSAttributedString* messageText = [self textForMessage: messageDict
												   controlView: controlView];
		[headerText drawAtPoint: NSMakePoint( cellFrame.origin.x , cellFrame.origin.y) ];
		NSRect messageRect = NSMakeRect( cellFrame.origin.x, cellFrame.origin.y + [headerText size].height, 
										cellFrame.size.width, cellFrame.size.height - [headerText size].height );
		[messageText drawWithRect: messageRect options: NSStringDrawingUsesLineFragmentOrigin];
		
	}
}

- (NSAttributedString*)headerForMessage:(NSDictionary*)messageDict
							controlView:(NSView*)controlView
{
	NSString* header = headerStringForASLMessageDict(messageDict);
	NSAttributedString* headerAttributed = [[NSAttributedString alloc] initWithString: header
																		   attributes: 
											[self headerAttributesWithControlView: controlView]];
	return headerAttributed;
}

- (NSAttributedString*)textForMessage:(NSDictionary*)messageDict 
						  controlView:(NSView*)controlView
{
	
	NSString* message = [messageDict objectForKey: kMFLogKeyMessage];
	NSAttributedString* messageAttributed = [[NSAttributedString alloc] initWithString: message
																			attributes: 
											 [self textAttributesWithControlView: controlView]];
	return messageAttributed;
}

- (NSDictionary*)headerAttributesWithControlView:(NSView*)controlView
{
	NSDictionary* attributes = [self textAttributesWithControlView: controlView];
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithDictionary: attributes];
	[dict setObject: [NSFont boldSystemFontOfSize: 11.0] forKey: NSFontAttributeName];
	return [dict copy];
}

- (NSDictionary*)textAttributesWithControlView:(NSView*)controlView
{
	BOOL current = ([[controlView window] firstResponder] == controlView && 
					[[controlView window] isKeyWindow]);
	
	NSMutableParagraphStyle* par = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[par setLineBreakMode: NSLineBreakByCharWrapping];
	NSColor* color = current && [self isHighlighted] ?
		[NSColor whiteColor] : [NSColor blackColor];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			color, NSForegroundColorAttributeName,
			[NSFont systemFontOfSize:11.0], NSFontAttributeName,
			[par copy], NSParagraphStyleAttributeName,
			nil];
}

- (CGFloat)heightForCellInWidth:(CGFloat)width
{
	NSDictionary* messageDict = [self representedObject];
	NSString* key = [NSString stringWithFormat: @"%d", messageDict];
	if ([heightCache objectForKey: key])
		return [[heightCache objectForKey: key] floatValue];
	else
	{
		NSAttributedString* header = [self headerForMessage:messageDict controlView: [self controlView]];
		
		CGFloat textHeight = 0;
		textHeight += [header size].height;
		
		NSDictionary* attributes = [self textAttributesWithControlView: [self controlView]];
		NSArray* lines = [[messageDict objectForKey: kMFLogKeyMessage] componentsSeparatedByString:@"\n"];
		for (NSString* line in lines)
		{
			NSSize lineSize = [[line stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]]
							   sizeWithAttributes: attributes];
			float numLines = ceilf(lineSize.width / width);		
			textHeight += lineSize.height * numLines;
		}
		
		[heightCache setObject: [NSNumber numberWithFloat: textHeight] forKey: key];
		return textHeight;
	}

}

@end
