//
//  MGActionButton.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/15/08.
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

#import "MGActionButton.h"


@implementation MGActionButton
- (void)mouseDown:(NSEvent*)theEvent
{
	[self highlight: YES];
	
	NSPoint point = [self convertPoint:[self bounds].origin toView:nil];
	point.y -= NSHeight([self frame]) + 4;
	point.x -= 1;
	
	NSEvent *event = [NSEvent mouseEventWithType:[theEvent type]
										location:point
								   modifierFlags:[theEvent modifierFlags]
									   timestamp:[theEvent timestamp]
									windowNumber:[[theEvent window] windowNumber]
										 context:[theEvent context]
									 eventNumber:[theEvent eventNumber]
									  clickCount:[theEvent clickCount]
										pressure:[theEvent pressure]];
	[NSMenu popUpContextMenu:[self menu] withEvent:event forView:self];
	[self mouseUp:[[NSApplication sharedApplication] currentEvent]];
}

- (void)mouseUp:(NSEvent*)event
{
	[self highlight: NO];
}
@end
