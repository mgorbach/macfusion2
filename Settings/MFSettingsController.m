//  MFSettingsController.m
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

#import "MFSettingsController.h"
#import "MFClient.h"
#import "MFClientFS.h"
#import "MFFilesystemCell.h"
#import "MFConstants.h"
#import "MFError.h"
#import "MGTransitioningTabView.h"
#import "MFFilesystemTableView.h"
#import "MFPreferencesController.h"

@interface MFSettingsController(PrivateAPI)

@end
@implementation MFSettingsController
- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		client = [MFClient sharedClient];
		[NSApp setDelegate: self];
		[client setDelegate: self];
		creatingNewFS = NO;
		if ([client setup])
		{
		}
		else
		{
			NSAlert* alert = [NSAlert alertWithMessageText:@"Could not connect to macfusion agent."
							defaultButton:@"OK"
						  alternateButton:@""
							  otherButton:@""
								 informativeTextWithFormat:@"Macfusion settings will now quit."];
			[alert setAlertStyle: NSCriticalAlertStyle];
			[alert runModal];
			[NSApp terminate:self];

		}
		
	}
	return self;
}

# pragma mark Handling Notifications
- (void)awakeFromNib
{
	NSCell* testCell = [[MFFilesystemCell alloc] init];
	[[filesystemTableView tableColumnWithIdentifier:@"test"] 
	 setDataCell: testCell];
	NSMenu* tableViewMenu = [[NSMenu alloc] initWithTitle:@"Tableview Menu"];
	[tableViewMenu addItemWithTitle:@"Mount"
							 action:@selector(mount)
					  keyEquivalent:@""];
	[tableViewMenu addItemWithTitle:@"Unmount"
							 action:@selector(unmount)
					  keyEquivalent:@""];
	[tableViewMenu addItemWithTitle:@"Edit"
							 action:@selector(editSelectedFilesystem:)
					  keyEquivalent:@""];
	
	[[filesystemTableView window] center];
	[filesystemTableView bind:@"filesystems"
					 toObject:filesystemArrayController
				  withKeyPath:@"arrangedObjects"
					  options:nil];
	[filesystemTableView setController: self];
	fsBeingEdited = nil;
}

- (void)applicationWillFinishLaunching:(NSNotification*)note
{

}

# pragma mark Table Delegate Methods


# pragma mark IBActions
- (void)popupButtonClicked:(id)sender
{
	NSPopUpButton* filesystemAddButton = (NSPopUpButton*)sender;
	MFClientPlugin* selectedPlugin = [[filesystemAddButton selectedItem]
									  representedObject];
	MFClientFS* fs = [client newFilesystemWithPlugin: selectedPlugin];
	NSUInteger selectionIndex = [[client filesystems] indexOfObject: fs];
	if (selectionIndex != NSNotFound)
	{
		[filesystemArrayController setSelectionIndex: selectionIndex];
		creatingNewFS = YES;
		[self editFilesystem: fs];
	}
}

- (IBAction)showPreferences:(id)sender
{
	MFLogS(self, @"ShowPreferences initialized");
	if (!preferencesController)
		preferencesController = [[MFPreferencesController alloc] initWithWindowNibName:@"MFPreferences"];
	[preferencesController showWindow:self];
}

- (IBAction)startMenuItem:(id)sender
{
	NSString* menuItemBundlePath = (NSString*)menulingUIBundlePath();
	NSArray* launchedBundleIDs = [[[NSWorkspace sharedWorkspace] launchedApplications] valueForKey:@"NSApplicationBundleIdentifier"];
	if ([launchedBundleIDs containsObject: @"org.mgorbach.macfusion2.menuling"])
	{
		MFLogS(self, @"Menuling already runing.");
		return;
	}
	else
	{
		[[NSWorkspace sharedWorkspace] launchApplication: menuItemBundlePath];
	}
}

# pragma mark View Construction
- (NSView*)editingViewForFS:(MFClientFS*)fs
{
	filesystemConfigurationViewControllers = [[fs configurationViewControllers] mutableCopy];
	NSTabView* tabView = [MGTransitioningTabView new];
	[tabView setFont: [NSFont systemFontOfSize: 
					   [NSFont systemFontSizeForControlSize: NSSmallControlSize]]];
	[tabView setControlSize: NSSmallControlSize];
	
	float view_width = 300;
	float tabview_x = 20;
	float tabview_y = 38;
	
	if (filesystemConfigurationViewControllers && [filesystemConfigurationViewControllers count] > 0)
	{
		[[filesystemConfigurationViewControllers allValues] makeObjectsPerformSelector:@selector(setRepresentedObject:)
																			withObject:fs];

		// TODO: Simplify the ordering of the views in the tabview
		// TODO: Allow adjustable height
		NSView* mainView = [[filesystemConfigurationViewControllers objectForKey: kMFUIMainViewKey] view];
		NSView* advancedView = [[filesystemConfigurationViewControllers objectForKey: kMFUIAdvancedViewKey] view];
		NSView* mfView = [[filesystemConfigurationViewControllers objectForKey: kMFUIMacfusionAdvancedViewKey] view];
		
		if (mainView)
		{
			NSTabViewItem* mainViewItem = [NSTabViewItem new];
			[mainViewItem setLabel: @"Main"];
			[mainViewItem setView: mainView];
			[tabView addTabViewItem: mainViewItem];
		}
		else
		{
			MFLogS(self, @"No main view found");
		}
		

		if (advancedView)
		{
			NSTabViewItem* advancedViewItem = [NSTabViewItem new];
			[advancedViewItem setLabel: @"Advanced"];
			[advancedViewItem setView: advancedView];
			[tabView addTabViewItem: advancedViewItem];
//			[tabView selectTabViewItem: advancedViewItem];
		}
		
		NSTabViewItem* mfViewItem = [NSTabViewItem new];
		[mfViewItem setLabel: @"Macfusion"];
		[mfViewItem setView: mfView];
		[tabView addTabViewItem: mfViewItem];
		

		for(NSTabViewItem* item in [tabView tabViewItems])
			[[item view] setFrame:
			 [mainView frame]];
		
		[mainView setFrame: NSMakeRect(300, 100, 300, 150)];
//		MFLogS(self, @"Main %@ Advanced %@", NSStringFromRect([mainView frame]),
//			   NSStringFromRect([advancedView frame]));
		[tabView setFrame: NSMakeRect( 0, 0, tabview_x+view_width, tabview_y+150 )];
//		MFLogS(self, @"Content area %@", NSStringFromRect([tabView contentRect]));
//		MFLogS(self, @"Main %@ Advanced %@", NSStringFromRect([mainView frame]),
//			   NSStringFromRect([advancedView frame]));

		return tabView;
	}
	else
	{
		MFLogS(self, @"No view loaded");
		return nil;
	}
}

- (void)addTopViewToView:(NSView*)view 
			  filesystem:(MFClientFS*)fs
{
	NSBundle* bundle = [NSBundle bundleWithIdentifier: @"org.mgorbach.macfusion2.MFCore"];
	NSViewController* nameViewController = [[NSViewController alloc] initWithNibName: @"topView"
																			  bundle: bundle];
	[nameViewController setRepresentedObject: fs];
	[filesystemConfigurationViewControllers setObject: nameViewController forKey: @"Top"];
	NSRect nameViewFrame = [[nameViewController view] frame];
	NSRect originalViewFrame = [view frame];
	[view setFrameSize: NSMakeSize( originalViewFrame.size.width, originalViewFrame.size.height + nameViewFrame.size.height)];
	[view addSubview: [nameViewController view]];
	[[nameViewController view] setFrameOrigin: NSMakePoint( 0,  originalViewFrame.size.height)];
}

- (NSView*)wrapViewInOKCancel:(NSView*)innerView;
{
	NSInteger buttonWidth = 80;
	NSInteger buttonHeight = 25;
	NSInteger buttonRightPadding = 5;
	NSInteger buttonBottomPadding = 5;
	NSInteger buttonXDistance = 0;
	NSInteger buttonAreaHeight = 2*buttonBottomPadding + buttonHeight;
	
	NSView* outerView = [[NSView alloc] init];
	
	[outerView setFrameSize: NSMakeSize([innerView frame].size.width, 
	[innerView frame].size.height +  buttonAreaHeight)];
	
	[outerView addSubview: innerView];
	[innerView setFrame: NSMakeRect(0, buttonAreaHeight, [innerView frame].size.width, 
	[innerView frame].size.height)];
	 
	NSRect okButtonFrame = NSMakeRect([outerView frame].size.width-buttonRightPadding-buttonWidth, 
									  buttonBottomPadding, 
									  buttonWidth, 
									  buttonHeight);
	NSButton* okButton = [[NSButton alloc] initWithFrame: okButtonFrame];
	[okButton setBezelStyle: NSRoundedBezelStyle];
	[okButton setTitle:@"OK"];
	[okButton setTarget: self];
	[okButton setAction:@selector(filesystemEditOKClicked:)];
	[okButton setKeyEquivalent:@"\r"];
	 
	 
	NSRect cancelButtonFrame = NSMakeRect(okButtonFrame.origin.x - buttonXDistance- buttonWidth,
	buttonBottomPadding,
	buttonWidth, buttonHeight);
	NSButton* cancelButton = [[NSButton alloc] initWithFrame: cancelButtonFrame];
	[cancelButton setBezelStyle: NSRoundedBezelStyle];
	[cancelButton setTitle:@"Cancel"];
	[cancelButton setTarget: self];
	[cancelButton setAction:@selector(filesystemEditCancelClicked:)];
	[cancelButton setKeyEquivalent:@"\e"];
	 
	[outerView addSubview:cancelButton];
	[outerView addSubview: okButton];
	 
	 
	return outerView;
}

# pragma mark Action Methods
- (void)deleteFilesystem:(MFClientFS*)fs
{
	if ([fs isUnmounted] || [fs isFailedToMount])
	{
		NSString* messageText = [NSString stringWithFormat: @"Are you sure you want to delete the filesystem %@?", fs.name];
		NSAlert* deleteConfirmation = [NSAlert new];
		[deleteConfirmation setMessageText: messageText];
		[deleteConfirmation addButtonWithTitle:@"OK"];
		NSButton* cancelButton = [deleteConfirmation addButtonWithTitle:@"Cancel"];
		[cancelButton setKeyEquivalent:@"\e"];
		[deleteConfirmation setAlertStyle: NSCriticalAlertStyle];
		[deleteConfirmation beginSheetModalForWindow: [filesystemTableView window]
														  modalDelegate:self
														 didEndSelector:@selector(deleteConfirmationAlertDidEnd:returnCode:contextInfo:)
															contextInfo:fs];
	}
	else
	{
		MFLogS(self, @"Can't delete FS");
	}
}

- (void)deleteConfirmationAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)code contextInfo:(void*)context
{
	MFClientFS* fs = (MFClientFS*)context;
	if (code == NSAlertAlternateReturn)
	{
		
	}
	else if (code == NSAlertDefaultReturn)
	{
		[client deleteFilesystem: fs];
	}
}
- (void)editFilesystem:(MFClientFS*)fs
{
	// MFLogS(self, @"Editing fs %@", fs);
	NSWindow* parent = [filesystemTableView window];
	NSWindow* mySheetWindow = [[NSWindow alloc] init];
	
	NSView* editView = [self wrapViewInOKCancel: [self editingViewForFS: fs]];
	[self addTopViewToView: editView filesystem:fs];
	if (editView)
	{
		[mySheetWindow setFrame: [editView frame] display:YES];
		[mySheetWindow setContentSize: [editView frame].size];
		[mySheetWindow setContentView: editView];
		[fs beginEditing];
		fsBeingEdited = fs;
		
		[NSApp beginSheet: mySheetWindow
		   modalForWindow: parent
			modalDelegate: self 
		   didEndSelector: @selector(sheetDidEnd:)
			  contextInfo: fs];
	}
}

- (void)toggleMountOnFilesystem:(MFClientFS*)fs
{
	if ([fs isMounted])
	{
		[fs unmount];
	}
	else if ([fs isUnmounted] || [fs isFailedToMount])
	{
		[fs setClientFSDelegate: self];
		[fs mount];
	}
}


# pragma mark Notification
- (void)filesystemDidChangeStatus:(MFClientFS*)fs
{
	if ([fs isFailedToMount])
	{
		if ([fs error])
		{
			[NSApp presentError:[fs error]
				 modalForWindow:[filesystemTableView window]
					   delegate:nil
			 didPresentSelector:nil
					contextInfo:nil];
		}
		else
		{
			MFLogS(@"No error");
		}
	}
}


# pragma mark Editing Mechanics
- (void)filesystemEditOKClicked:(id)sender
{
	MFClientFS* fs = fsBeingEdited;
	for(NSViewController* controller in [filesystemConfigurationViewControllers allValues])
	{
		BOOL ok = [controller commitEditing];
		if (!ok)
		{
			MFLogS(self, @"Failed to commit edits %@", controller);
		}
	}
	
	NSError* error = [fs endEditingAndCommitChanges: YES];
	if (error)
	{
		[NSApp presentError: error
			 modalForWindow: [sender window]
				   delegate: nil
		 didPresentSelector: nil
				contextInfo: nil ];
	}
	else
	{
		[NSApp endSheet: [sender window]];
	}
	
	creatingNewFS = NO;
}


- (void)filesystemEditCancelClicked:(id)sender
{
	MFClientFS* fs = fsBeingEdited;
	for(NSViewController* controller in [filesystemConfigurationViewControllers allValues])
	{
		BOOL ok = [controller commitEditing];
		if (!ok)
		{
			MFLogS(self, @"Failed to commit edits %@", controller);
		}
	}
	[fs endEditingAndCommitChanges: NO];
	if (creatingNewFS)
		[client deleteFilesystem: fsBeingEdited];
	creatingNewFS = NO;
	[NSApp endSheet: [sender window]];

}

- (void)sheetDidEnd:(NSWindow*)sheet
{
	[sheet orderOut:self];
	fsBeingEdited = nil;
	filesystemConfigurationViewControllers = nil;
}


- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error
{
	if ([error code] == kMFErrorCodeMountFaliure)
	{
		NSString* newDescription = [NSString stringWithFormat: @"Could not mount filesystem: %@", [error localizedDescription]];
		return [MFError errorWithErrorCode:kMFErrorCodeMountFaliure description:newDescription];
	}
	else
	{
		return error;
	}
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	NSString* fsLocation = [@"~/Library/Application Support/Macfusion/Filesystems" stringByExpandingTildeInPath];
	MFLogS(self, @"Lastpath %@", [filename stringByDeletingLastPathComponent]);
	if ([[filename stringByDeletingLastPathComponent] isEqualToString: fsLocation])
	{
		NSString* uuid = [[filename lastPathComponent] stringByDeletingPathExtension];
		[self editFilesystem: [client filesystemWithUUID: uuid]];
	}
	else
	{
		MFLogS(self, @"Not opening file. It is in the wrong place");
	}
		
	return YES;
}

# pragma mark Misc
- (void)windowWillClose:(NSWindow*)window
{
	[NSApp terminate:self];
}

- (void)finalize
{
	[super finalize];
	[client setDelegate:nil];
}

@synthesize client;

@end
