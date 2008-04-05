//
//  MFMenulingAppDelegate.m
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
			NSAlert* alert = [NSAlert new];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText: @"Could not connect to macfusion agent."];
			[alert setInformativeText: @"Macfusion Menuling will now quit."];
			[alert setAlertStyle: NSCriticalAlertStyle];
			[alert runModal];
			[NSApp terminate:self];
		}
	}
	
	[client setDelegate: self];
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
	[statusItem setTitle:@""];
	NSMenu* menu = [[NSMenu alloc] initWithTitle:@"Macfusion2"];
	[menu setDelegate: self];
	[statusItem setMenu: menu];
	NSImage* menuIcon = [NSImage imageNamed:@"MacFusion_Menu_Dark.png"];
	NSImage* menuIconSelected = [NSImage imageNamed:@"MacFusion_Menu_Light.png"];
	[statusItem setHighlightMode: YES];
	[statusItem setImage: menuIcon];
	[statusItem setAlternateImage: menuIconSelected];
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

- (void)filesystemDidChangeStatus:(MFClientFS*)fs
{
	if ([fs isMounted])
	{
		[fs setClientFSDelegate: nil];
	}
	else if ([fs isFailedToMount])
	{
		if ([fs error])
		{
			[NSApp presentError: [fs error]];
		}
		else
		{
			MFLogS(self, @"No error to present on faliure. FS %@", fs);
		}
		
		[fs setClientFSDelegate: nil];
	}
}

- (void)openConfiguration:(id)sender
{
	[[NSWorkspace sharedWorkspace] launchApplication: 
	 (NSString*)mfcMainBundlePath()];
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

# pragma mark Error Handling
- (void)handleConnectionDied
{
	// We won't try to recover since we're a background app. Let's just die ...
	MFLogS(self, @"Terminating due to dead agent connection");
	[NSApp terminate:self];
}

@end