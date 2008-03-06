	//
//  MFSettingsController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/16/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFSettingsController.h"
#import "MFClient.h"
#import "MFClientFS.h"
#import "MFFilesystemCell.h"
#import "MFConstants.h"
#import "MFError.h"
#import "MGTransitioningTabView.h"

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
- (void)handleFailureNotification:(NSNotification*)note
{
	MFClientFS* fs = [note object];
	if ([[filesystemArrayController arrangedObjects] 
		 containsObject: fs])
	{
		[NSApp presentError: [fs error]
						 modalForWindow:[NSApp keyWindow]
							   delegate:nil
					 didPresentSelector:nil
							contextInfo:nil];
		[[NSNotificationCenter defaultCenter]
		 removeObserver:self name:kMFClientFSMountedNotification object:fs];
		[[NSNotificationCenter defaultCenter]
		 removeObserver:self name:kMFClientFSFailedNotification object:fs];
	}
	
}

- (void)handleMountNotification:(NSNotification*)note
{
	MFClientFS* fs = [note object];
	if ([[filesystemArrayController arrangedObjects] 
		 containsObject: fs])
	{
		[NSApp presentError:[fs error]
						 modalForWindow:[NSApp keyWindow]
							   delegate:nil
					 didPresentSelector:nil
							contextInfo:nil];
		[[NSNotificationCenter defaultCenter]
		 removeObserver:self name:kMFClientFSMountedNotification object:fs];
		[[NSNotificationCenter defaultCenter]
		 removeObserver:self name:kMFClientFSFailedNotification object:fs];
	}
}

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
	
	NSTableColumn* c = [[filesystemTableView tableColumns] objectAtIndex: 0];
	[c setDataCell: [[MFFilesystemCell alloc] init]];
	[filesystemTableView setMenu: tableViewMenu];
	[[filesystemTableView window] center];
	
	// D&D
	[filesystemTableView registerForDraggedTypes: [NSArray arrayWithObject: kMFFilesystemDragType ]];
	[filesystemTableView setDataSource: self];
	[filesystemTableView setDelegate: self];
}

- (void)applicationWillFinishLaunching:(NSNotification*)note
{
	
}

# pragma mark Table Delegate Methods
- (void) tableView: (NSTableView *) tableView 
   willDisplayCell: (NSCell*) cell 
	forTableColumn: (NSTableColumn *) tableColumn 
			   row: (int) row
{
	[cell setRepresentedObject: [client.persistentFilesystems objectAtIndex: row]];
}

# pragma mark Tableview D&D
- (BOOL)tableView:(NSTableView *)tableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
	 toPasteboard:(NSPasteboard*)pboard
{
	NSMutableArray* uuids = [NSMutableArray array];
	NSUInteger count = [rowIndexes count];
	
	int i;
	NSUInteger index = [rowIndexes firstIndex];
	for(i = 0; i < count; i++)
	{
		NSString* uuid = [[[filesystemArrayController arrangedObjects] objectAtIndex: index] uuid];
		[uuids addObject: uuid];
		index = [rowIndexes indexGreaterThanIndex:index];
	}
	
	if ([uuids count] > 0)
	{
		[pboard declareTypes:[NSArray arrayWithObject:kMFFilesystemDragType] owner:self];
		[pboard setPropertyList:uuids forType:kMFFilesystemDragType];
		return YES;
	}
	else
	{
		return NO;
	}
	

}

- (NSDragOperation)tableView:(NSTableView*)tableView 
				validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
	return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard* pb = [info draggingPasteboard];
	NSArray* uuidsBeingMoved = [pb propertyListForType:kMFFilesystemDragType];
	[client moveUUIDS:uuidsBeingMoved toRow:row];
	return YES;
}


# pragma mark Actions
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
		[self editSelectedFilesystem: self];
	}
}

- (NSView*)editingViewForFS:(MFClientFS*)fs
{
	filesystemConfigurationViewControllers = [[fs delegate] configurationViewControllers];
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

		NSView* mainView = [[filesystemConfigurationViewControllers objectForKey: kMFUIMainViewKey] view];
		NSView* advancedView = [[filesystemConfigurationViewControllers objectForKey: kMFUIAdvancedViewKey] view];
		MFLogS(self, @"Main %@ Advanced %@", NSStringFromRect([mainView frame]), NSStringFromRect([advancedView frame]));
		NSSize viewSize = [mainView frame].size;
//		NSSize viewSize = NSMakeSize( 400,  300);
		
		if (mainView)
		{
			NSTabViewItem* mainViewItem = [NSTabViewItem new];
			[mainViewItem setLabel: @"Main"];
			[mainViewItem setView: mainView];
			[tabView addTabViewItem: mainViewItem];
//			[tabView selectTabViewItem: mainViewItem];
//			[mainView setFrame: NSMakeRect(0, 0, 300, 150)];
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
			[advancedView setFrame: NSMakeRect(0, 0, 300, 150)];
		}
		

		for(NSTabViewItem* item in [tabView tabViewItems])
			[[item view] setFrame:
			 [mainView frame]];
		
		[mainView setFrame: NSMakeRect(300, 100, 300, 150)];
		MFLogS(self, @"Main %@ Advanced %@", NSStringFromRect([mainView frame]),
			   NSStringFromRect([advancedView frame]));
		[tabView setFrame: NSMakeRect( 0, 0, tabview_x+view_width, tabview_y+150 )];
		MFLogS(self, @"Content area %@", NSStringFromRect([tabView contentRect]));
		MFLogS(self, @"Main %@ Advanced %@", NSStringFromRect([mainView frame]),
			   NSStringFromRect([advancedView frame]));

		return tabView;
	}
	else
	{
		MFLogS(self, @"No view loaded");
		return nil;
	}
}

- (NSView*)wrapViewInOKCancel:(NSView*)innerView;
{
	 NSInteger buttonWidth = 80;
	 NSInteger buttonHeight = 25;
	 NSInteger buttonRightPadding = 5;
	 NSInteger buttonBottomPadding = 5;
	 NSInteger buttonXDistance = 0;
	 NSInteger buttonAreaHeight = 2*buttonBottomPadding + buttonHeight ;
	 
	 NSView* outerView = [[NSView alloc] init];
	 
	 [outerView setFrameSize: NSMakeSize([innerView frame].size.width, 
	 [innerView frame].size.height +  buttonAreaHeight)];
	 
	 [outerView addSubview: innerView];
	 [innerView setFrame: NSMakeRect(0, buttonAreaHeight, [innerView frame].size.width, 
	 [innerView frame].size.height)];
	 
	 NSRect okButtonFrame = NSMakeRect([outerView frame].size.width-buttonRightPadding-buttonWidth,
	 buttonBottomPadding,
	 buttonWidth, buttonHeight);
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

- (void)editSelectedFilesystem:(id)sender
{
	if ([filesystemArrayController selectionIndex] != NSNotFound)
	{
		NSWindow* parent = [NSApp keyWindow];
		NSWindow* mySheetWindow = [[NSWindow alloc] init];
		
		MFClientFS* fs = [[filesystemArrayController selectedObjects] objectAtIndex: 0];
		
		NSView* editView = [self wrapViewInOKCancel: [self editingViewForFS: fs]];
		if (editView)
		{
			[mySheetWindow setFrame: [editView frame] display:YES];
			[mySheetWindow setContentSize: [editView frame].size];
			[mySheetWindow setContentView: editView];
			[fs beginEditing];
			
			[NSApp beginSheet: mySheetWindow
			   modalForWindow: parent
				modalDelegate: self 
			   didEndSelector: @selector(sheetDidEnd:)
				  contextInfo: fs];
		}
		else
		{
			MFLogS(self, @"Editing view is nil");
		}

	}
}

- (void)mountSelectedFilesystem:(id)sender
{
	if ([filesystemArrayController selectionIndex] != NSNotFound)
	{
		MFClientFS* fs = [[filesystemArrayController selectedObjects] objectAtIndex: 0];
		if ([fs isMounted])
		{
			[fs unmount];
		}
		else if ([fs isUnmounted] || [fs isFailedToMount])
		{
			[fs mount];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(handleFailureNotification:) 
														 name:kMFClientFSFailedNotification
													   object:fs];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(handleMountNotification:) 
														 name:kMFClientFSFailedNotification
													   object:fs];
		}
	}
}

- (void)filesystemEditOKClicked:(id)sender
{
	MFClientFS* fs = [[filesystemArrayController selectedObjects]
						objectAtIndex: 0];
	
	NSError* error = [fs endEditingAndCommitChanges: YES];
	if (error)
	{
		[NSApp presentError: error
							modalForWindow: [sender window]
								  delegate: self
								didPresentSelector: @selector(didPresentErrorWithRecovery: contextInfo:)
							  contextInfo: nil ];
	}
	else
	{
		[NSApp endSheet: [sender window]];
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

- (void)filesystemEditCancelClicked:(id)sender
{
	MFClientFS* fs = [[filesystemArrayController selectedObjects]
					  objectAtIndex: 0];
	[fs endEditingAndCommitChanges: NO];
	[NSApp endSheet: [sender window]];
}

- (void)sheetDidEnd:(NSWindow*)sheet
{
	[sheet orderOut:self];
	filesystemConfigurationViewControllers = nil;
}

- (void)windowWillClose:(NSWindow*)window
{
	[NSApp terminate:self];
}

- (void)clientStatusChanged
{
	[filesystemTableView reloadData];
}

- (void)finalize
{
	[super finalize];
	[client setDelegate:nil];
	NSLog(@"Finalizing MFSettingsController");
}

@synthesize client;

@end
