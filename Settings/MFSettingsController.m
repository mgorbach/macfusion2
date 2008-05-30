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
#import "MFCore.h"
#import "MFLogReader.h"
#import "MFLogViewerController.h"
#import "MFClientFSUI.h"
#import "MGTestView.h"

@interface MFSettingsController(PrivateAPI)
- (BOOL)validateFSMenuItem:(NSMenuItem*)item;
@end

@implementation MFSettingsController
- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		[NSApp setDelegate: self];
		creatingNewFS = NO;
		menuArgumentFS = nil;
		client = [MFClient sharedClient];
		[client setDelegate: self];
	}
	return self;
}

# pragma mark Agent connection

- (void)agentStartFailedSheetDidEnd:(NSAlert*)sheet returnCode:(NSInteger)returnCode contextInfo:(void*)context
{
	[NSApp terminate: self];
}

- (void)agentStartSheetDidEnd:(NSAlert*)sheet returnCode:(NSInteger)returnCode context:(void*)context
{
	NSAlert* serverStartAlert = sheet;
	[[serverStartAlert window] orderOut: self];
	[NSApp endSheet: [serverStartAlert window]]; 
	
	if ([[serverStartAlert suppressionButton] state])
		mfcSetStateForAgentLoginItem(YES);
	
	if (returnCode == NSAlertSecondButtonReturn)
	{
		[NSApp terminate: self];
	}
	else if (returnCode == NSAlertFirstButtonReturn)
	{
		mfcLaunchAgent();
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval: 1.5]];
		
		if ([client establishCommunication])
		{
			[client fillInitialStatus];
		}
		else
		{
			NSAlert* faliureAlert = [NSAlert alertWithMessageText:@"Could not start or connect to the macfusion agent"
													defaultButton:@"OK"
												  alternateButton:@""
													  otherButton:@""
										informativeTextWithFormat:@"Macfusion will Quit."];
			[faliureAlert setAlertStyle: NSCriticalAlertStyle];
			[faliureAlert beginSheetModalForWindow: [filesystemTableView window]
									 modalDelegate:self
									didEndSelector:@selector(agentStartFailedSheetDidEnd:returnCode:contextInfo:)
									   contextInfo:nil];
		}
	}
}

- (BOOL)setup
{
	mfcSetupTrashMonitoring();
	if ([client establishCommunication])
	{
		[client fillInitialStatus];
		return YES;
	}
	else
	{
		BOOL agentRunning = NO;
		NSArray* runingIDs = [[[NSWorkspace sharedWorkspace] launchedApplications] valueForKey:@"NSApplicationBundleIdentifier"];
		// MFLogS(self, @"Runing ids are %@", runingIDs);
		for(NSString* id in runingIDs)
		{
			if ([id isEqualToString: kMFAgentBundleIdentifier])
			{
				agentRunning = YES;
				break;
			}
		}
		
		if (agentRunning)
		{
			// Agent is runing. Wait a bit for it to set up IPC
			MFLogS(self, @"Waiting for agent");
			NSDate* stopDate = [[NSDate date] addTimeInterval: 5.0];
			[[NSRunLoop currentRunLoop] runUntilDate: stopDate];
			if ([client establishCommunication])
			{
				[client fillInitialStatus];
				return YES;
			}
			else
			{
				return NO;
			}
		}
		else
		{
			// Try to start the agent process
			MFLogS(self, @"Agent not runing. Request to Start.");
			NSAlert* serverStartAlert = [NSAlert new];
			[serverStartAlert setMessageText: @"The macfusion agent process is not started"];
			[serverStartAlert setInformativeText: @"Would you like to start the agent?\nOtherwise, Macfusion will Quit."];
			[serverStartAlert setShowsSuppressionButton: YES];
			[serverStartAlert addButtonWithTitle:@"Start"];
			[serverStartAlert addButtonWithTitle:@"Quit"];
			[[serverStartAlert suppressionButton] setTitle: @"Start agent automatically on login"];
			[[serverStartAlert suppressionButton] setState: mfcGetStateForAgentLoginItem()];
			[serverStartAlert beginSheetModalForWindow:[filesystemTableView window]
																 modalDelegate:self
																didEndSelector:@selector(agentStartSheetDidEnd:returnCode:context:)
																   contextInfo:nil];
		}
		
	}
	
	return NO;
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
	[self setup];
}

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
	if (!preferencesController)
		preferencesController = [[MFPreferencesController alloc] initWithWindowNibName:@"MFPreferences"];
	[preferencesController showWindow:self];
}

- (IBAction)showLogViewer:(id)sender
{
	if (!logViewerController)
		logViewerController = [[MFLogViewerController alloc] initWithWindowNibName:@"logViewer"];
	[logViewerController showWindow:self];
}

- (IBAction)startMenuItem:(id)sender
{
	NSString* menuItemBundlePath = (NSString*)mfcMenulingBundlePath();
	[[NSWorkspace sharedWorkspace] launchApplication: menuItemBundlePath];
}

- (IBAction)deleteSelectedFilesystem:(id)sender
{
	if ([[filesystemArrayController selectedObjects] count] > 0)
	{
		for(MFClientFS* fs in [filesystemArrayController selectedObjects])
		{
			[self deleteFilesystem: fs];
		}
	}
}

- (IBAction)filterLogForFilesystem:(id)sender
{
	if ([sender isKindOfClass: [MFClientFS class]])
	{
		[self showLogViewer: self];
		[logViewerController filterForFilesystem: sender];
	}
}

# pragma mark View Construction


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
	[okButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
	 
	 
	NSRect cancelButtonFrame = NSMakeRect(okButtonFrame.origin.x - buttonXDistance- buttonWidth,
	buttonBottomPadding,
	buttonWidth, buttonHeight);
	NSButton* cancelButton = [[NSButton alloc] initWithFrame: cancelButtonFrame];
	[cancelButton setBezelStyle: NSRoundedBezelStyle];
	[cancelButton setTitle:@"Cancel"];
	[cancelButton setTarget: self];
	[cancelButton setAction:@selector(filesystemEditCancelClicked:)];
	[cancelButton setKeyEquivalent:@"\e"];
	[cancelButton setAutoresizingMask: NSViewMaxYMargin | NSViewMinXMargin];
	 
	[outerView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
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
		MFLogSO(self, fs, @"Can't delete FS %@", fs);
	}
}


- (void)deleteConfirmationAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)code contextInfo:(void*)context
{
	MFClientFS* fs = (MFClientFS*)context;
	if (code == NSAlertSecondButtonReturn)
	{
		
	}
	else if (code == NSAlertFirstButtonReturn)
	{
		[client deleteFilesystem: fs];
	}
}
- (void)editFilesystem:(MFClientFS*)fs
{
	// MFLogS(self, @"Editing fs %@", fs);
	if (!fs || [fs isMounted] || [fs isWaiting])
		return;
	
	NSWindow* parent = [filesystemTableView window];
	NSWindow* mySheetWindow = [[NSWindow alloc] init];
	
	NSView* editingViewForFS = [fs editingView];
	[(MGTransitioningTabView*)editingViewForFS setDelegate: self];
	
	if (!editingViewForFS)
	{
		MFLogSO(self, fs, @"Editing view nil");
		return;
	}
	
	NSView* fullEditView = [self wrapViewInOKCancel: 
							[fs addTopViewToView: editingViewForFS]];
	if (fullEditView)
	{
		[mySheetWindow setFrame: [fullEditView frame] display:YES];
		[mySheetWindow setContentSize: [fullEditView frame].size];
		[mySheetWindow setContentView: fullEditView];
		[fs beginEditing];
		fsBeingEdited = fs;
		
		[NSApp beginSheet: mySheetWindow
		   modalForWindow: parent
			modalDelegate: self 
		   didEndSelector: @selector(sheetDidEnd:)
			  contextInfo: fs];
	}
}


- (void)tabView:(NSTabView *)tabView 
	didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	MGTransitioningTabView* myTabView = (MGTransitioningTabView*)tabView;
	NSWindow* sheetWindow = [NSApp keyWindow];
	NSRect oldSheetFrame = [sheetWindow frame];
	NSSize oldTabViewSize = [tabView frame].size;
	CGFloat deltaX = [sheetWindow frame].size.width - oldTabViewSize.width;
	CGFloat deltaY = [sheetWindow frame].size.height - oldTabViewSize.height;
	NSSize newtabViewSize = [myTabView sizeWithTabviewItem: tabViewItem];
	NSSize newSize = NSMakeSize(newtabViewSize.width+deltaX, newtabViewSize.height+deltaY);
	[sheetWindow setFrame: NSMakeRect(oldSheetFrame.origin.x-0.5*(newSize.width-oldSheetFrame.size.width), 
									  oldSheetFrame.origin.y-(newSize.height-oldSheetFrame.size.height), 
									  newSize.width, newSize.height) 
				  display:YES 
				  animate:YES];
}

- (void)toggleMountOnFilesystem:(MFClientFS*)fs
{
	if ([fs isMounted])
	{
		[self unmountFilesystem: fs];
	}
	else if ([fs isUnmounted] || [fs isFailedToMount])
	{
		[self mountFilesystem: fs];
	}
}

- (void)unmountFilesystem:(MFClientFS*)fs
{
	if ([fs isMounted])
		[fs unmount];
}

- (void)mountFilesystem:(MFClientFS*)fs
{
	if ([fs isUnmounted] || [fs isFailedToMount])
	{
		[fs setClientFSDelegate: self];
		[fs mount];
	}
}

- (void)revealFilesystem:(MFClientFS*)fs
{
	[[NSWorkspace sharedWorkspace] selectFile:[fs filePath]
					 inFileViewerRootedAtPath:nil];
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
			MFLogSO(self, fs, @"No error for fs %@", fs);
		}
	}
}

# pragma mark Editing Mechanics
- (void)filesystemEditOKClicked:(id)sender
{
	MFClientFS* fs = fsBeingEdited;
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
	// MFLogS(self, @"Lastpath %@", [filename stringByDeletingLastPathComponent]);
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

# pragma mark Menu UI Stuff
- (void)menuNeedsUpdate:(NSMenu*)menu
{
	NSInteger clickedRow = [filesystemTableView clickedRow];
	// MFLogS(self, @"Updating menu clicked row %d", clickedRow);
	[self willChangeValueForKey: @"menuArgumentFS"];
	if (clickedRow != -1 && clickedRow != NSNotFound)
		menuArgumentFS = [[filesystemArrayController arrangedObjects] objectAtIndex: clickedRow];
	else
	{
		if ([[filesystemArrayController selectedObjects] count] > 0)
			menuArgumentFS = [[filesystemArrayController selectedObjects] objectAtIndex: 0];
		else
			menuArgumentFS = nil;
	}
	[self didChangeValueForKey:@"menuArgumentFS"];
	for (NSMenuItem* item in [menu itemArray])
		[item setEnabled: [self validateFSMenuItem: item]];
}

- (BOOL)validateFSMenuItem:(NSMenuItem*)item
{
	// MFLogS(self, @"Validating FS item %@", item );
	if ([[item title] isEqualToString: @"Mount"])
	{
		return ([menuArgumentFS isUnmounted] || [menuArgumentFS isFailedToMount]);
	}
	if ([[item title] isEqualToString: @"Edit"])
	{
		return ([menuArgumentFS isUnmounted] || [menuArgumentFS isFailedToMount]);
	}
	if ([[item title] isEqualToString: @"Unmount"])
	{
		return [menuArgumentFS isMounted];
	}
	
	if ([[item title] isEqualToString: @"Reveal"])
	{
		return (menuArgumentFS.filePath != nil);
	}
	if ([[item title] isEqualToString: @"Log"])
		return (menuArgumentFS != nil);
		
	return NO;
}

# pragma mark Misc
- (void)windowWillClose:(NSWindow*)window
{
	[NSApp terminate:self];
}

# pragma mark Error Recovery
- (void)finalFaliureAlertDidEnd:(NSAlert*)alert
					 returnCode:(NSInteger)returnValue
					contextInfo:(void*)context
{
	[NSApp terminate: self];
}

- (void)connectionDidDieAlertDidEnd:(NSAlert*)alert
						 returnCode:(NSInteger)returnValue 
						contextInfo:(void*)context
{
	[[alert window] orderOut:self];
	if (returnValue == NSAlertFirstButtonReturn)
		[NSApp terminate: self];
	else if (returnValue == NSAlertSecondButtonReturn)
	{
		mfcLaunchAgent();
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval: 1.5]];
		if ([client establishCommunication])
			[client fillInitialStatus];
		else
		{
			NSAlert* finalFaliureAlert = [NSAlert alertWithMessageText:@"Failed to restart Macfusion Agent"
														 defaultButton:@"Quit"
													   alternateButton:@"" 
														   otherButton:@""
											 informativeTextWithFormat:@"The Macfusion Agent failed to restart.\nMacfusion must quit."];
			[finalFaliureAlert setAlertStyle: NSCriticalAlertStyle];
			[finalFaliureAlert beginSheetModalForWindow:[filesystemTableView window]
										  modalDelegate:self
										 didEndSelector:@selector(finalFaliureAlertDidEnd:returnCode:contextInfo:)
											contextInfo:nil];
		}
	}
}

- (void)handleConnectionDied
{
		
	if (mfcClientIsUIElement())
		[NSApp terminate:self];
	
	NSAlert* connectDidDieAlert = [[NSAlert alloc] init];
	[connectDidDieAlert addButtonWithTitle:@"Quit"];
	[connectDidDieAlert addButtonWithTitle:@"Restart Agent"];
	[connectDidDieAlert setAlertStyle: NSCriticalAlertStyle];
	[connectDidDieAlert setMessageText:@"The Macfusion Agent has quit unexpectedly"];
	[connectDidDieAlert setInformativeText:@"Would you like to try and restart the agent so macfusion can \
	 continue working?\nOtherwise, Macfusion must Quit."];
	[connectDidDieAlert beginSheetModalForWindow:[filesystemTableView window]
								   modalDelegate:self
								  didEndSelector:@selector(connectionDidDieAlertDidEnd:returnCode:contextInfo:)
									 contextInfo:nil]; 
	
}

- (void)finalize
{
	[super finalize];
	[client setDelegate:nil];
}

@synthesize client;

@end
