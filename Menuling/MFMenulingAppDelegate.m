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
#import "MFConstants.h"
#import "MFError.h"
#import <Carbon/Carbon.h>

#define MENU_ICON_SIZE 24

@interface MFMenulingAppDelegate(PrivateAPI)
- (void)registerHotkey;
@end

@implementation MFMenulingAppDelegate
- (id)init
{
	if (self = [super init])
	{
		[NSApp setDelegate: self];
		client = [MFClient sharedClient];
		[self registerHotkey];
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

OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
						 void *userData)
{
	[(MFMenulingAppDelegate*)userData connectToServer: nil];
	return noErr;
}

- (void)registerHotkey
{
	EventHotKeyRef myHotkeyRef;
	EventHotKeyID myHotkeyId;
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	myHotkeyId.signature='htk1';
	myHotkeyId.id=1;
	RegisterEventHotKey(40, cmdKey+optionKey+controlKey, myHotkeyId, GetApplicationEventTarget(), 0, &myHotkeyRef);
	
	InstallApplicationEventHandler(&MyHotKeyHandler,1,&eventType,self,NULL);
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
	
	if ([[qmController window] isVisible]
		&& [NSApp keyWindow] != [qmController window])
	{
		[NSApp activateIgnoringOtherApps: YES];
		[[qmController window] makeKeyAndOrderFront: self];
	}
	else if (![[qmController window] isVisible])
	{	
		[NSApp activateIgnoringOtherApps: YES];
		[qmController showWindow:self];
	}
	else if ([NSApp keyWindow] == [qmController window])
	{
		[[qmController window] close];
		[NSApp deactivate];
	}
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
	else if ([fs isUnmounted] || [fs isFailedToMount])
	{
		[fs setClientFSDelegate: self];
		[fs mount];
	}
}

/*
- (void)fsMounted:(NSNotification*)note
{
	MFClientFS* fs = [note object];
	if (! [fs isPersistent] )
		return;

}

- (void)fsFailedToMount:(NSNotification*)note
{
	MFClientFS* fs = [note object];
	if (! [fs isPersistent] )
		return;
	
	NSError* error = [[note object] error];
	[NSApp presentError: error];
	
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:kMFClientFSMountedNotification
	 object:fs];
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:kMFClientFSFailedNotification
	 object:fs];
}
 */

- (void)filesystemDidChangeStatus:(MFClientFS*)fs
{
	if ([fs isMounted])
	{
		
	}
	else if ([fs isFailedToMount])
	{
		if ([fs error])
		{
			[NSApp presentError: [fs error]];
		}
		else
		{
			NSLog(@"No error");
		}
	}
}

- (void)applicationWillTerminate:(NSNotification*)note
{
}

- (NSError*)application:(NSApplication*)app willPresentError:(NSError*)error
{
	[NSApp activateIgnoringOtherApps:YES];
	if ([error code] == kMFErrorCodeCustomizedFaliure)
		return error;
	
	NSString* newDescription = [NSString stringWithFormat: @"Could not mount filesystem: %@",
								[error localizedDescription]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  newDescription, NSLocalizedDescriptionKey,
							  nil];
	MFError* newError = [MFError errorWithDomain:kMFErrorDomain
										 code:kMFErrorCodeMountFaliure
										userInfo:userInfo];
	return newError;
}

- (void)quit:(id)sender
{
	[NSApp terminate: self];
}

@end