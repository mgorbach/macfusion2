//
//  MFMenulingAppDelegate.m
//  MacFusion2
//
//  Created by Michael Gorbach on 2/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MFMenulingAppDelegate.h"
#import "MFClient.h"
#import "MFClientFS.h"

@implementation MFMenulingAppDelegate
- (id)init
{
	if (self = [super init])
	{
		[NSApp setDelegate: self];
		client = [MFClient sharedClient];
		if (![client setup])
		{
			NSAlert* alert = [NSAlert alertWithMessageText: @"Could not connecto macfusion agent. Quitting"
							defaultButton:@"OK"
										   alternateButton:@"" otherButton:@"" informativeTextWithFormat:@""];
			[alert runModal];
		}
	}
	return self;
}

- (void)awakeFromNib
{
	[NSApp setDelegate: self];
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: NSSquareStatusItemLength ];
	if (!statusItem)
		[NSApp terminate:self];
	[statusItem setTitle:@"MF2"];
	NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Macfusion2"];
	[menu setDelegate: self];
	[statusItem setMenu: menu];
}

- (void)menuNeedsUpdate:(NSMenu*)menu
{
	for(NSMenuItem* item in [menu itemArray])
		[menu removeItem: item];
	for(MFClientFS* fs in [client filesystems])
	{
		NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:fs.name
													  action:@selector(fsSelected:)
											   keyEquivalent:@""];
		NSImage* icon = [[NSImage alloc] initWithContentsOfFile: fs.iconPath ];
		[icon setSize: NSMakeSize( 24 ,  24) ];
		[item setImage: icon];
		[menu addItem: item];
		
	}
}

- (void)fsSelected:(id)sender
{
	NSLog(@"FS Selected %@", sender);
}

- (void)applicationWillTerminate:(NSNotification*)note
{
}

@end