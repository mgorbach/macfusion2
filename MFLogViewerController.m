//
//  MFLogViewerController.m
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

#import "MFLogViewerController.h"
#import "MFLogReader.h"
#import "MFClient.h"
#import "MFClientFS.h"
#import "MFLogging.h"
#import "MFPreferences.h"

#define kMessageSearchCategoryTag 0
#define kSenderSearchCategoryTag 1
#define kSubsystemSearchCategoryTag 2
#define kUUIDSearchCategoryTag 3
#define kAllSearchCategoryTag 4

static NSString* kSearchToolbarItemIdentifier = @"searchItem";
static NSString* kFSFilterToolbarItemIdentifier = @"fsFilterItem";
static NSString* kAutoscrollToolbarItemIdentifier = @"autoscroll";

@interface MFLogViewerController(PrivateAPI)
@property(readwrite, retain) NSPredicate* filterPredicate;
@property(readwrite, retain) NSPredicate* searchPredicate;
@end

@implementation MFLogViewerController
- (id)initWithWindowNibName:(NSString*)name
{
	if (self = [super initWithWindowNibName:name])
	{
		logReader = [MFLogReader sharedReader];
		[logReader start];
		self.filterPredicate = nil;
		self.searchPredicate = nil;
	}
	
	return self;
}

+ (NSSet*)keyPathsForValuesAffectingFullLogPredicate
{
	return [NSSet setWithObjects: 
			@"filterPredicate", @"searchPredicate", nil];
}

- (void)windowDidLoad
{
	[logTableView bind:@"logMessages"
			  toObject:logArrayController
		   withKeyPath:@"arrangedObjects"
			   options:nil];
	[logArrayController addObserver: self
				forKeyPath:@"arrangedObjects"
				   options:(NSKeyValueObservingOptions)0
				   context:self];
	[logArrayController bind:@"filterPredicate"
					toObject:self
				 withKeyPath:@"fullLogPredicate"
					 options:nil];
	
	[logTableView scrollRowToVisible: [logTableView numberOfRows] - 1];
	NSMenu* fsMenu = [[NSMenu alloc] initWithTitle:@"Filesystems"];
	[fsMenu setDelegate: self];
	filesystemFilterPopup = [[NSPopUpButton alloc] initWithFrame: NSMakeRect(0, 0, 200, 30)];
	[filesystemFilterPopup setMenu: fsMenu];
	[self menuNeedsUpdate: fsMenu];
	
	autoScrollButton = [[NSButton alloc] initWithFrame: NSMakeRect(0, 0, 200, 30)];
	[[autoScrollButton cell] setButtonType: NSSwitchButton];
	[autoScrollButton setTitle:@"AutoScroll"];
	[autoScrollButton setAction: @selector(setAutoScroll:)];
	[autoScrollButton setState: [[MFPreferences sharedPreferences] getBoolForPreference: kMFPrefsAutoScrollLog]];
	
	logSearchField = [[NSSearchField alloc] initWithFrame: NSMakeRect(0, 0, 200, 30)];
	[logSearchField setAction: @selector(searchFieldUpdated:)];
	[logSearchField setTarget: self];
	[[logSearchField cell] setPlaceholderString: @"Search Logs"];
	NSMenu* searchCategoryMenu = [[NSMenu alloc] initWithTitle:@"Search Categories"];
	[searchCategoryMenu addItemWithTitle:@"All" action:@selector(searchCategoryChanged:) keyEquivalent:@""];
	[[searchCategoryMenu itemAtIndex:0] setTag: kAllSearchCategoryTag];
	[searchCategoryMenu addItemWithTitle:@"Sender" action:@selector(searchCategoryChanged:) keyEquivalent:@""];
	[[searchCategoryMenu itemAtIndex:1] setTag: kSenderSearchCategoryTag];
	[searchCategoryMenu addItemWithTitle: @"Message" action:@selector(searchCategoryChanged:) keyEquivalent:@""];
	[[searchCategoryMenu itemAtIndex:2] setTag: kMessageSearchCategoryTag];
	[searchCategoryMenu addItemWithTitle: @"Subsystem" action:@selector(searchCategoryChanged:) keyEquivalent:@""];
	[[searchCategoryMenu itemAtIndex:3] setTag: kSubsystemSearchCategoryTag];
	[searchCategoryMenu addItemWithTitle: @"UUID" action:@selector(searchCategoryChanged:) keyEquivalent:@""];
	[[searchCategoryMenu itemAtIndex:4] setTag: kUUIDSearchCategoryTag];
	[[logSearchField cell] setSearchMenuTemplate: searchCategoryMenu];
	[self searchCategoryChanged: [searchCategoryMenu itemWithTag: kAllSearchCategoryTag]];
	
	
	NSToolbar* toolbar = [[NSToolbar alloc] initWithIdentifier: @"Test"];
	[toolbar setAllowsUserCustomization: NO];
	[toolbar setAutosavesConfiguration: NO];
	[toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
	[toolbar setDelegate: self];
	[[self window] setToolbar: toolbar];
}

# pragma mark Updating
- (IBAction)refresh:(id)sender
{
	// NSLog(@"count %d", [logTableView numberOfRows]);
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
		// NSLog(@"Controlled observes change!");
		// NSLog(@"logArrayController content count %d", [[logArrayController arrangedObjects] count]);
		[logTableView reloadData];
		if ([[MFPreferences sharedPreferences] getBoolForPreference: kMFPrefsAutoScrollLog])
			[logTableView scrollRowToVisible: [logTableView numberOfRows] - 1];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void) setAutoScroll:(id)sender
{
	[[MFPreferences sharedPreferences] setBool: [sender state]
								 forPreference: kMFPrefsAutoScrollLog ];
}

# pragma mark Menus
- (void)menuNeedsUpdate:(NSMenu*)menu
{
	// NSLog(@"Menu needs update");
	for(id item in [menu itemArray])
		[menu removeItem: item];
	
	[menu setShowsStateColumn: NO];
	[menu addItemWithTitle:@"All"
					action:@selector(fsSelected:)
			 keyEquivalent:@""];
	for(MFClientFS* fs in [[MFClient sharedClient] filesystems])
	{
		NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle: fs.name
														  action: @selector(fsSelected:)
												   keyEquivalent:@""];
		[menuItem setRepresentedObject: fs];
		[menu addItem: menuItem];
	}
}

- (void)fsSelected:(id)sender
{
	if ([[sender representedObject] isKindOfClass: [MFClientFS class]])
	{
		// MFLogS(self, @"Setting filter");
		self.filterPredicate =
		 [NSPredicate predicateWithFormat: @"self.UUID == %@", 
		  [[sender representedObject] uuid]];
	}
	else
	{
		self.filterPredicate = nil;
	}
}

# pragma mark Search & Filter
- (NSPredicate*)fullLogPredicate
{
	if (filterPredicate && searchPredicate)
		return [NSCompoundPredicate andPredicateWithSubpredicates:
			[NSArray arrayWithObjects: 
			 filterPredicate, searchPredicate, nil]];
	if (filterPredicate)
		return filterPredicate;
	if (searchPredicate)
		return searchPredicate;
	
	return nil;
}

- (void)searchFieldUpdated:(id)sender
{
	NSString* text = [logSearchField stringValue];
	
	if (!text || [text length] == 0)
	{	
		self.searchPredicate = nil;
		return;
	}
	
	NSPredicate* messagePredicate = [NSPredicate predicateWithFormat: @"self.%@ CONTAINS[cd] %@", kMFLogKeyMessage, text];;
	NSPredicate* senderPredicate = [NSPredicate predicateWithFormat: @"self.%@ CONTAINS[cd] %@", kMFLogKeySender, text];
	NSPredicate* subsystemPredicate = [NSPredicate predicateWithFormat: @"self.%@ CONTAINS[cd] %@", kMFLogKeySubsystem, text];
	NSPredicate* uuidPredicate = [NSPredicate predicateWithFormat:@"self.%@ CONTAINS[cd] %@", kMFLogKeyUUID, text];
	
	if (searchCategory == kAllSearchCategoryTag)
		self.searchPredicate = [NSCompoundPredicate orPredicateWithSubpredicates: 
				[NSArray arrayWithObjects: messagePredicate, senderPredicate, subsystemPredicate, uuidPredicate, nil]];
	if (searchCategory == kMessageSearchCategoryTag)
		self.searchPredicate = messagePredicate;
	if (searchCategory == kSubsystemSearchCategoryTag)
		self.searchPredicate = subsystemPredicate;
	if (searchCategory == kSenderSearchCategoryTag)
		self.searchPredicate = senderPredicate;
	if (searchCategory == kUUIDSearchCategoryTag)
		self.searchPredicate = uuidPredicate;
	
}

- (void)searchCategoryChanged:(id)sender
{
	[[logSearchField cell] setPlaceholderString: [NSString stringWithFormat:
												  @"%@", [sender title]]];
	searchCategory = [sender tag];
	[self searchFieldUpdated: logSearchField];
	
	for(NSMenuItem* m in [[sender menu] itemArray])
		[m setState: NO];
	[sender setState: YES];
}

- (IBAction)filterForFilesystem:(MFClientFS*)fs
{
	for(NSMenuItem* item in [filesystemFilterPopup itemArray])
		if ([item representedObject] == fs)
		{
			[filesystemFilterPopup selectItem: item];
			[self fsSelected: item];
		}
}

# pragma mark Toolbars
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
			kSearchToolbarItemIdentifier,
			kAutoscrollToolbarItemIdentifier,
			kFSFilterToolbarItemIdentifier,
			NSToolbarFlexibleSpaceItemIdentifier, 
			NSToolbarSpaceItemIdentifier, 
			NSToolbarSeparatorItemIdentifier, 
			nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *)toolbar 
{
    return [NSArray arrayWithObjects: kFSFilterToolbarItemIdentifier,
			kAutoscrollToolbarItemIdentifier, kSearchToolbarItemIdentifier, 
			NSToolbarFlexibleSpaceItemIdentifier, nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
itemForItemIdentifier:(NSString *)itemIdentifier
willBeInsertedIntoToolbar:(BOOL)flag
{
	NSToolbarItem* toolbarItem;
	if ([itemIdentifier isEqualTo: kFSFilterToolbarItemIdentifier])
	{
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: kFSFilterToolbarItemIdentifier];
		[toolbarItem setLabel: @"Filesystem"];
		[toolbarItem setPaletteLabel: [toolbarItem label]];
		[toolbarItem setView: filesystemFilterPopup];
	}
	if ([itemIdentifier isEqualTo: kAutoscrollToolbarItemIdentifier])
	{
		toolbarItem  = [[NSToolbarItem alloc] initWithItemIdentifier: kAutoscrollToolbarItemIdentifier];
		[toolbarItem setLabel: @""];
		[toolbarItem setPaletteLabel: [toolbarItem label]];
		[toolbarItem setView: autoScrollButton];
	}
	if ([itemIdentifier isEqualTo: kSearchToolbarItemIdentifier])
	{
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: kSearchToolbarItemIdentifier];
		[toolbarItem setLabel: @"Search"];
		[toolbarItem setPaletteLabel: [toolbarItem label]];
		[toolbarItem setView: logSearchField];
		[toolbarItem setMinSize: NSMakeSize(75, 20)];
		[toolbarItem setMaxSize: NSMakeSize(300, 20)];
	}
	
	return toolbarItem;
}

@synthesize filterPredicate, searchPredicate;
@end
