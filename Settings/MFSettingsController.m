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
#import "MFEditingController.h"
#import "MFPreferences.h"

@interface MFSettingsController(PrivateAPI)
- (void)editFilesystem:(MFClientFS*)fs;
- (void)toggleFilesystem:(MFClientFS*)fs;
- (void)deleteFilesystem:(MFClientFS*)fs;
- (NSMenu*)newFilesystemMenu;
- (void)connectionOK;
@end

@implementation MFSettingsController
- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		[NSApp setDelegate: self];
		client = [MFClient sharedClient];
		[client setDelegate: self];
	}
	return self;
}

# pragma mark Agent connection

- (void)agentStartFailedSheetDidEnd:(NSAlert*)sheet
						 returnCode:(NSInteger)returnCode
						contextInfo:(void*)context
{
	[NSApp terminate: self];
}

- (void)agentStartSheetDidEnd:(NSAlert*)sheet 
				   returnCode:(NSInteger)returnCode
					  context:(void*)context
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
		[[NSRunLoop currentRunLoop] runUntilDate:[[NSDate date] addTimeInterval: 3]];
		
		if ([client establishCommunication])
		{
			[client fillInitialStatus];
			[self connectionOK];
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
		NSArray* runingIDs = [[[NSWorkspace sharedWorkspace] launchedApplications] 
							  valueForKey:@"NSApplicationBundleIdentifier"];
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
	
	[[MFPreferences sharedPreferences] addObserver: self forKeyPath: kMFPrefsAutosize options:0 context:self];
	[filesystemTableView setIntercellSpacing: NSMakeSize(10, 0)];
	
	NSWindow* window = [filesystemTableView window];
	[window center];
	
	[filesystemTableView bind:@"filesystems"
					 toObject:filesystemArrayController
				  withKeyPath:@"arrangedObjects"
					  options:nil];
	[filesystemTableView setController: self];
}

- (void) resizeWindowForContent 
{
	if ([[MFPreferences sharedPreferences] getBoolForPreference: kMFPrefsAutosize])
	{
		// Autosize the window vertically
		NSWindow* window = [filesystemTableView window];
		NSInteger maxRows = 10;
		NSInteger minRows = 2;
		NSInteger rows, filesystemCount;
		filesystemCount = [[filesystemArrayController arrangedObjects] count];
		
		if (filesystemCount < minRows) rows = minRows;
		else if (filesystemCount > maxRows) rows = maxRows;
		else rows = filesystemCount;
		

		NSSize windowContentSize = [(NSView*)[window contentView] frame].size;
		NSInteger tableViewOldVerticalPixels = [[filesystemTableView superview] frame].size.height;
		NSInteger tableViewNewVerticalPixels = (rows * [filesystemTableView rowHeight]);
		tableViewNewVerticalPixels += (rows)*[filesystemTableView intercellSpacing].height;
		NSRect windowFrame = [NSWindow contentRectForFrameRect:[window frame]
													 styleMask:[window styleMask]];
		NSSize size = NSMakeSize( windowContentSize.width, windowContentSize.height 
								 - tableViewOldVerticalPixels + tableViewNewVerticalPixels);
		NSRect newWindowFrame = [NSWindow frameRectForContentRect:
								 NSMakeRect( NSMinX( windowFrame ), NSMaxY( windowFrame ) 
											- size.height, size.width, size.height )
														  styleMask:[window styleMask]];
		[window setFrame:newWindowFrame display:YES animate:[window isVisible]];
		[window setMinSize: NSMakeSize(300, newWindowFrame.size.height) ];
		[window setMaxSize: NSMakeSize( FLT_MAX, newWindowFrame.size.height )];
	}
	else
	{
		NSWindow* window = [filesystemTableView window];
		[window setMinSize: NSMakeSize(300, 100)];
		[window setMaxSize: NSMakeSize( FLT_MAX, FLT_MAX)];
	}
}

- (void)connectionOK
{
	[filesystemTableView reloadData];
	[filesystemTableView noteHeightOfRowsWithIndexesChanged: 
	 [NSIndexSet indexSetWithIndexesInRange: 
	  NSMakeRange(0, [client.filesystems count])]];
	
	// Set delegate for all mounted filesystems
	[[client.filesystems filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:
	 @"self.status == %@", kMFStatusFSMounted]] 
	 makeObjectsPerformSelector: @selector(setClientFSDelegate:) withObject:self];
	
	[filesystemArrayController addObserver:self
								forKeyPath:@"arrangedObjects"
								   options:NSKeyValueObservingOptionNew
								   context:self];
	[self resizeWindowForContent];
	[newFSActionButton setMenu: [self newFilesystemMenu]];
}

- (void)applicationWillFinishLaunching:(NSNotification*)note
{
	if ([self setup])
		[self connectionOK];
}


# pragma mark IBActions
- (void)newFSPopupClicked:(id)sender
{
	MFClientPlugin* selectedPlugin = [sender representedObject];
	MFClientFS* fs = [client newFilesystemWithPlugin: selectedPlugin];
	NSUInteger selectionIndex = [[client filesystems] indexOfObject: fs];
	if (selectionIndex != NSNotFound)
	{
		[filesystemArrayController setSelectionIndex: selectionIndex];
		[self resizeWindowForContent];
		NSInteger editReturn = [MFEditingController editFilesystem: fs 
								   onWindow: [filesystemTableView window]];
		if (editReturn == kMFEditReturnCancel)
		{
			// Delete newly created filesystems if editing was canceled
			[client deleteFilesystem: fs];
		}
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

# pragma mark Filesystem Methods
- (NSArray*)selectedFilesystems
{
	MFClientFS* clickedFS = [filesystemTableView clickedFilesystem];
	NSArray* selectedFilesystems = [[filesystemArrayController arrangedObjects] objectsAtIndexes:
						   [filesystemTableView selectedRowIndexes]];
	if (clickedFS)
	{
		if ([selectedFilesystems containsObject: clickedFS])
			return selectedFilesystems;
		else
			return [NSArray arrayWithObject: clickedFS];
	}
	else
	{
		return [[filesystemArrayController arrangedObjects] objectsAtIndexes:
				[filesystemTableView selectedRowIndexes]];
	}

}

- (void)editFilesystem:(MFClientFS*)fs
{
	if (!fs || [fs isMounted] || [fs isWaiting])
		return;
	
	NSWindow* parent = [filesystemTableView window];
	[MFEditingController editFilesystem: fs onWindow: parent];
}

- (void)toggleFilesystem:(MFClientFS*)fs
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


- (void)deleteFilesystems:(NSArray*)filesystems
{
	NSMutableArray* filesystemsToDelete = [filesystems mutableCopy];
	for(MFClientFS* fs in filesystems)
	{
		if( ! ([fs isUnmounted] || [fs isFailedToMount]) )
		{
			[filesystemsToDelete removeObject: fs];
			MFLogS(self, @"Can't delete filesystem %@", fs);
		}
	}

	if ([filesystemsToDelete count] > 0)
	{
		NSString* fsWord = [filesystemsToDelete count] == 1 ? @"filesystem" : @"filesystems";
		NSString* messageText = [NSString stringWithFormat: @"Are you sure you want to delete the %@ %@?", fsWord,
								 [[filesystemsToDelete valueForKey: kMFFSNameParameter] componentsJoinedByString: @", "]];
		NSAlert* deleteConfirmation = [NSAlert new];
		[deleteConfirmation setMessageText: messageText];
		[deleteConfirmation addButtonWithTitle:@"OK"];
		[deleteConfirmation setInformativeText: @"This action can not be undone."];
		NSButton* cancelButton = [deleteConfirmation addButtonWithTitle:@"Cancel"];
		[cancelButton setKeyEquivalent:@"\e"];
		[deleteConfirmation setAlertStyle: NSCriticalAlertStyle];
		[deleteConfirmation beginSheetModalForWindow: [filesystemTableView window]
									   modalDelegate:self
									  didEndSelector:@selector(deleteConfirmationAlertDidEnd:returnCode:contextInfo:)
										 contextInfo:filesystemsToDelete];
	}
}

- (void)deleteFilesystem:(MFClientFS*)fs
{
	[self deleteFilesystems: [NSArray arrayWithObject: fs]];
}
	

# pragma mark Selected Action Methods

- (IBAction)filterLogForSelectedFS:(id)sender
{
	[self showLogViewer: self];
	NSArray* selectedFilesystems = [self selectedFilesystems];
	if ([selectedFilesystems count] == 1)
	{
		[logViewerController filterForFilesystem: 
		 [selectedFilesystems objectAtIndex: 0]];
	}
}

- (IBAction)editSelectedFS:(id)sender
{
	NSArray* selectedFilesystems = [self selectedFilesystems];
	if ([selectedFilesystems count] == 1)
	{
		[self editFilesystem: [selectedFilesystems objectAtIndex: 0]];
	}
	else
	{
		return;
	}
}

- (IBAction)toggleSelectedFS:(id)sender
{
	NSArray* selectedFilesystems = [self selectedFilesystems];
	for (MFClientFS* fs in selectedFilesystems)
		[self toggleFilesystem: fs];
}

- (IBAction)revealConfigForSelectedFS:(id)sender
{
	for(MFClientFS* fs in [self selectedFilesystems])
	{
		[[NSWorkspace sharedWorkspace]  selectFile:fs.filePath
						  inFileViewerRootedAtPath:nil];
	}
}

- (IBAction)revealSelectedFS:(id)sender
{
	for(MFClientFS* fs in [self selectedFilesystems])
	{
		if ([fs isMounted])
			[[NSWorkspace sharedWorkspace] selectFile: nil
							 inFileViewerRootedAtPath: fs.mountPath ];
	}
}

- (IBAction)duplicateSelectedFS:(id)sender
{
}

- (IBAction)deleteSelectedFS:(id)sender
{
	NSLog(@"DSFS %@", [self selectedFilesystems]);
	[self deleteFilesystems: [self selectedFilesystems]];
}


- (void)deleteConfirmationAlertDidEnd:(NSAlert*)alert returnCode:(NSInteger)code contextInfo:(void*)context
{
	NSArray* filesystemsToDelete = (NSArray*)context;
	if (code == NSAlertSecondButtonReturn)
	{
		
	}
	else if (code == NSAlertFirstButtonReturn)
	{
		for(MFClientFS* fs in filesystemsToDelete)
			[client deleteFilesystem: fs];
	}
}


# pragma mark Notification
- (void)filesystemDidChangeStatus:(MFClientFS*)fs
{
	[filesystemTableView statusChangedForFS: fs];
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
			MFLogSO(self, fs, @"No error for failed-to-mount fs %@", fs);
		}
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == self) {
		[self resizeWindowForContent];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
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

- (NSMenu*)newFilesystemMenu
{
	NSMenu* menu = [NSMenu new];
	[menu setTitle: @"New filesystems"];
	for( MFClientPlugin* plugin in [pluginArrayController arrangedObjects] )
	{
		NSMenuItem* item = [NSMenuItem new];
		[item setTitle: [plugin shortName]];
		[item setState: 0];
		[item setRepresentedObject: plugin];
		[item setTarget: self];
		[item setAction: @selector(newFSPopupClicked:)];
		[menu addItem: item];
	}

	return menu;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	NSArray* selectedFilesystems = [self selectedFilesystems];
	
	// If action has to do with filesystems, and none are selected, disable it
	if ( [selectedFilesystems count] == 0 && 
		[ NSStringFromSelector( [anItem action] ) rangeOfString: @"FS"].location != NSNotFound )
	{
		return NO;
	}
	else
	{
		MFClientFS* fs;
		// Validate all selected filesystems
		for (fs in selectedFilesystems)
		{
			if (action == @selector(toggleSelectedFS:))
			{
				if ([[NSSet setWithArray: 
					[selectedFilesystems valueForKey:@"status"]] count] > 1)
				{
					return NO;
				}
				
				if ([fs isWaiting])
					return NO;
				else if ([fs isMounted])
					[ (NSMenuItem*)anItem setTitle: @"Unmount" ];
				else if ([fs isUnmounted] || [fs isFailedToMount] )
					[ (NSMenuItem*)anItem setTitle: @"Mount" ];
			}
			
			if (action == @selector(revealSelectedFS:))
			{
				if (! [fs isMounted] )
					return NO;
			}
			
			if (action == @selector(deleteSelectedFS:))
			{
				if ([fs isMounted] || [fs isWaiting])
				{
					return NO;
				}
			}
			
			if (action == @selector(editSelectedFS:))
			{
				if ([selectedFilesystems count] > 1)
					return NO;
				
				if ( [fs isMounted] || [fs isWaiting] )
					return NO;
			}
		}
	}
	
	return YES;
}

# pragma mark Misc
- (void)windowWillClose:(NSWindow*)window
{
	[NSApp terminate:self];
}

- (IBAction)openMainSite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: 
	 [NSURL URLWithString: @"http://www.macfusionapp.org"]];
}

- (IBAction)openSupportSite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL: 
	 [NSURL URLWithString: @"http://www.macfusionapp.org/support.html"]];
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

#pragma mark Sparkle

- (BOOL)shouldPromptForPermissionToCheckForUpdates
{
	return NO;
}

- (BOOL)shouldPromptForPermissionToCheckForUpdatesToHostBundle:(NSBundle *)bundle
{
	return NO;
}

- (void)updaterWillRelaunchApplication
{
	MFLogS(self, @"Sparkle updating in progress");
	mfcKaboomMacfusion();
}

- (void)finalize
{
	[super finalize];
	[client setDelegate:nil];
}

@synthesize client;

@end
