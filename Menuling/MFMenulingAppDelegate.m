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
#import "MGNSImage.h"
#import "MFQuickMountController.h"

#define MENU_ICON_SIZE 24

@implementation MFMenulingAppDelegate
- (id)init
{
	if (self = [super init])
	{
		[NSApp setDelegate: self];
		client = [MFClient sharedClient];
		if (![client setup])
		{
			NSAlert* alert = [NSAlert alertWithMessageText:@"Could not connect to macfusion agent."
											 defaultButton:@"OK"
										   alternateButton:@""
											   otherButton:@""
								 informativeTextWithFormat:@"Macfusion Menuling will now quit."];
			[alert setAlertStyle: NSCriticalAlertStyle];
			[alert runModal];
			[NSApp terminate:self];
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

- (void)connectToServer:(id)sender
{
	if(!qmController)
	{
		qmController = [[MFQuickMountController alloc] initWithWindowNibName:@"QuickMount"];
	}
	
	[qmController showWindow:self];
	[NSApp activateIgnoringOtherApps: YES];
	[[qmController window] makeKeyWindow];
}

- (void)addCurrentlyMountedFilesystemsToMenu:(NSMenu*)menu
{
	NSArray* mountedFilesystems = client.mountedFilesystems;
	if ([mountedFilesystems count] > 0)
	{
		[menu addItem: [NSMenuItem separatorItem]];
		for(MFClientFS* fs in mountedFilesystems)
		{
			NSMenuItem* menuItem = [NSMenuItem new];
			NSString* title;
			if (fs.name && [fs.name length] > 0)
				title = fs.name;
			else
				title = fs.descriptionString;
			[menuItem setTitle: title];
			[menuItem setRepresentedObject: fs];
			[menuItem setAction: @selector(fsSelected:)];
			[menu addItem: menuItem];
		}
		[menu addItem: [NSMenuItem separatorItem]];
	}
}

- (NSMenu*)persistentFilesystemsSubMenu
{
	NSArray* persistentFilesystems = client.persistentFilesystems;
	if ([persistentFilesystems count] > 0)
	{
		NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Favorites"];
		for(MFClientFS* fs in persistentFilesystems)
		{
			NSMenuItem* menuItem = [NSMenuItem new];
			[menuItem setTitle: fs.name];
			[menuItem setRepresentedObject: fs];
			[menuItem setAction: @selector(fsSelected:)];
			if ([fs isMounted])
				[menuItem setState:YES];
			else
				[menuItem setState:NO];
			[menu addItem: menuItem];
		}
		
		[menu setShowsStateColumn:YES];
		return menu;
	}
	
	return nil;
}


- (void)menuNeedsUpdate:(NSMenu*)menu
{
	for(NSMenuItem* item in [menu itemArray])
		[menu removeItem: item];
	
	[menu addItemWithTitle: @"Connect to Server ..."
					action:@selector(connectToServer:)
			 keyEquivalent:@""];
	
	NSMenuItem* favoritesMenuItem = [NSMenuItem new];
	[favoritesMenuItem setTitle:@"Favorites"];
	[favoritesMenuItem setSubmenu: [self persistentFilesystemsSubMenu]];
	[menu addItem: favoritesMenuItem];
	
	[self addCurrentlyMountedFilesystemsToMenu: menu];
	
	[menu addItemWithTitle:@"Open Configuration ..."
					action:@selector(openConfiguration:)
			 keyEquivalent:@""];
	[menu addItemWithTitle: @"Quit"
					action:@selector(quit:)
			 keyEquivalent:@""];
}

- (void)fsSelected:(id)sender
{
	MFClientFS* fs = [sender representedObject];
	if ([fs isMounted])
	{
		[[NSWorkspace sharedWorkspace]
		 selectFile:nil inFileViewerRootedAtPath:fs.mountPath];
	}
	else if ([fs isUnmounted])
	{
		[fs mount];
	}
}

- (void)applicationWillTerminate:(NSNotification*)note
{
}

- (void)quit:(id)sender
{
	[NSApp terminate: self];
}

@end