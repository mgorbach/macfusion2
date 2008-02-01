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
#import "TestView.h"

@implementation MFSettingsController
- (id) init
{
	self = [super init];
	if (self != nil) {
		client = [MFClient sharedClient];
		[client setDelegate: self];
		if ([client establishCommunication])
		{
			[client fillInitialStatus];
		}
		else
		{
			[[NSAlert alertWithMessageText:@"Could not connect to macfusion agent."
							defaultButton:@"OK"
						  alternateButton:@""
							  otherButton:@""
				informativeTextWithFormat:@"Macfusion settings will now quit."] runModal];
			[NSApp terminate:self];
		}
	}
	return self;
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
	
	NSLog(@"Key equivalent value is %@", [mountButton keyEquivalent]);
	[filesystemCollectionView setMenu: tableViewMenu];
}

# pragma mark Table Delegate Methods
-(void)tableViewSelectionDidChange:(NSNotification*)note
{
	NSTableView* notifyingTableView = [note object];
	filesystemConfigurationViewController = nil;
	[configurationViewBox setContentView: nil];
	
	if (notifyingTableView == filesystemTableView)
	{
		if ([filesystemArrayController selectionIndex] != NSNotFound)
		{
			MFClientFS* fs = [[filesystemArrayController selectedObjects]
							  objectAtIndex: 0];
			MFClientPlugin* plugin = [client pluginWithID: [fs pluginID]];
			NSString* nibName = [plugin nibName];
			NSBundle* bundle = [NSBundle bundleWithPath: [plugin bundlePath]];
			if (nibName && bundle)
			{
				filesystemConfigurationViewController =
				[[NSViewController alloc] initWithNibName: nibName
												   bundle: bundle ];
				
				[filesystemConfigurationViewController setRepresentedObject: fs];
				[configurationViewBox setContentView: 
				 [filesystemConfigurationViewController view]];
			}
			else
			{
				NSLog(@"Failed to load interface for filesystem %@", fs);
			}

		}
		else
		{
			// No selection
			filesystemConfigurationViewController = nil;
			[configurationViewBox setContentView: nil];
		}
	}
}

- (NSCell *) tableView: (NSTableView *) tableView dataCellForTableColumn: (NSTableColumn *) tableColumn row: (NSInteger) row
{
    return [[MFFilesystemCell alloc] init];
}

- (void) tableView: (NSTableView *) tableView willDisplayCell: (NSCell*) cell forTableColumn: (NSTableColumn *) tableColumn row: (int) row
{
	[cell setRepresentedObject: [[client filesystems] objectAtIndex: row]];
}

# pragma mark Actions
- (void)popupButtonClicked:(id)sender
{
	NSPopUpButton* filesystemAddButton = (NSPopUpButton*)sender;
	MFClientPlugin* selectedPlugin = [[filesystemAddButton selectedItem]
									  representedObject];
	MFClientFS* fs = [client newFilesystemWithPlugin: selectedPlugin];
	NSLog(@"fs %@", fs);
	NSLog(@"list %@", [client filesystems]);
	NSUInteger selectionIndex = [[client filesystems] indexOfObject: fs];
	if (selectionIndex != NSNotFound)
	{
		[filesystemArrayController setSelectionIndex: selectionIndex];
	}
	else
	{
		NSLog(@"Failed to locate selection index for fs: %@",
			  fs);
	}
}

- (NSView*)filesystemEditingView
{
	NSInteger buttonWidth = 80;
	NSInteger buttonHeight = 25;
	NSInteger buttonRightPadding = 5;
	NSInteger buttonBottomPadding = 5;
	NSInteger buttonXDistance = 0;
	NSInteger buttonAreaHeight = 2*buttonBottomPadding + buttonHeight ;
	
	NSView* loadedView = [filesystemConfigurationViewController view];	
	NSView* outerView = [[NSView alloc] init];
	
	
	[outerView setFrameSize: NSMakeSize([loadedView frame].size.width, 
									   [loadedView frame].size.height +  buttonAreaHeight)];
	
	[outerView addSubview: loadedView];
	[loadedView setFrame: NSMakeRect(0, buttonAreaHeight, [loadedView frame].size.width, 
									   [loadedView frame].size.height)];
	
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
		MFClientPlugin* plugin = [client pluginWithID: [fs pluginID]];
		NSString* nibName = [plugin nibName];
		NSBundle* bundle = [NSBundle bundleWithPath: [plugin bundlePath]];
		if (nibName && bundle)
		{
			filesystemConfigurationViewController =
			[[NSViewController alloc] initWithNibName: nibName
											   bundle: bundle ];
			
			[filesystemConfigurationViewController setRepresentedObject: 
			 fs];

		
			NSView* editView = [self filesystemEditingView];
			[mySheetWindow setFrame: [editView frame] display:YES];
			[mySheetWindow setContentSize: [editView frame].size];
			[mySheetWindow setContentView: editView];

			[NSApp beginSheet: mySheetWindow
			   modalForWindow: parent
				modalDelegate: self 
			   didEndSelector: @selector(sheetDidEnd:)
				  contextInfo: nil];

			
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
		else if ([fs isUnmounted])
		{
			[fs mount];
		}
	}
}

- (void)filesystemEditOKClicked:(id)sender
{
	[NSApp endSheet: [sender window]];
}

- (void)filesystemEditCancelClicked:(id)sender
{
	[NSApp endSheet: [sender window]];
}

- (void)sheetDidEnd:(NSWindow*)sheet
{
	[sheet orderOut:self];
	filesystemConfigurationViewController = nil;
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
