//
//  MFEditingController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 6/16/08.
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

#import "MFEditingController.h"
#import "MGTransitioningTabView.h"
#import "MFClientFSUI.h"
#import "MFLogging.h"

@interface MFEditingController(PrivateAPI)
- (id)initWithFilesystem:(MFClientFS *)fs;
- (void)beginEditing;
- (void)filesystemEditOKClicked:(id)sender;
- (void)filesystemEditCancelClicked:(id)sender;
- (NSView *)wrapViewInOKCancel:(NSView *)innerView;
@end

@implementation MFEditingController

+ (NSInteger)editFilesystem:(MFClientFS *)fs onWindow:(NSWindow *)parentWindow {
	MFEditingController *editController = [[MFEditingController alloc] initWithFilesystem: fs];
	NSWindow *editWindow = [editController window];
	[editController beginEditing];
	
	if (parentWindow) {
		[NSApp beginSheet:editWindow
		   modalForWindow:parentWindow
			modalDelegate:editController 
		   didEndSelector:@selector(editSheetDidEnd:returnCode:contextInfo:)
			  contextInfo:fs];
		NSInteger editReturn = [NSApp runModalForWindow: editWindow];
		[NSApp endSheet:editWindow];
		[editWindow orderOut:self];
		return editReturn;
	} else {
		[editController showWindow:self];
		NSInteger editReturn = [NSApp runModalForWindow:editWindow];
		[editWindow close];
		return editReturn;
	}
}

- (id)initWithFilesystem:(MFClientFS *)fs {
	if (self = [super initWithWindow: nil]) {
		_fsBeingEdited = fs;
		NSWindow *editWindow = [[NSWindow alloc] init];
		NSView *editingViewForFS = [fs editingView];
		[(MGTransitioningTabView *)editingViewForFS setDelegate:self];
		
		if (!editingViewForFS) {
			MFLogSO(self, fs, @"Filesystem returned nil view for editing");
			return nil;
		}
		
		NSView *fullEditView = [self wrapViewInOKCancel:[fs addTopViewToView: editingViewForFS]];
		[editWindow setFrame:[fullEditView frame] display:YES];
		[editWindow setContentSize:[fullEditView frame].size];
		[editWindow setContentView:fullEditView];
		[self setWindow:editWindow];
	}
	
	return self;
}

- (void)beginEditing {
	[_fsBeingEdited beginEditing];
}

# pragma mark Editing Mechanics
- (void)filesystemEditOKClicked:(id)sender {
	NSError *error = [_fsBeingEdited endEditingAndCommitChanges:YES];
	if (error) {
		[NSApp presentError: error
			 modalForWindow: [self window]
				   delegate: nil
		 didPresentSelector: nil
				contextInfo: nil];
	} else {
		[NSApp stopModalWithCode:kMFEditReturnOK];
	}
}


- (void)filesystemEditCancelClicked:(id)sender {
	[_fsBeingEdited endEditingAndCommitChanges:NO];	
	[NSApp stopModalWithCode:kMFEditReturnCancel];
}

- (void)editSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)code contextInfo:(void *)info {
	[sheet orderOut:self];
}

# pragma mark View Construction
- (NSView *)wrapViewInOKCancel:(NSView *)innerView {
	NSInteger buttonWidth = 80;
	NSInteger buttonHeight = 32;
	NSInteger buttonRightPadding = 10;
	NSInteger buttonBottomPadding = 5;
	NSInteger buttonXDistance = 0;
	NSInteger ySpacingShift = 8;
	NSInteger buttonAreaHeight = 2*buttonBottomPadding + buttonHeight;
	NSInteger margin = 20;
	
	NSView *outerView = [[NSView alloc] init];
	
	[outerView setFrameSize:NSMakeSize([innerView frame].size.width + margin,[innerView frame].size.height +  buttonAreaHeight)];
	
	[outerView addSubview:innerView];
	[innerView setFrame:NSMakeRect(margin/2, buttonAreaHeight - ySpacingShift, [innerView frame].size.width,[innerView frame].size.height)];
	
	NSRect okButtonFrame = NSMakeRect([outerView frame].size.width-buttonRightPadding-buttonWidth,
									  buttonBottomPadding, 
									  buttonWidth, 
									  buttonHeight);
	NSButton *okButton = [[NSButton alloc] initWithFrame: okButtonFrame];
	[okButton setBezelStyle:NSRoundedBezelStyle];
	[okButton setTitle:@"OK"];
	[okButton setTarget:self];
	[okButton setAction:@selector(filesystemEditOKClicked:)];
	[okButton setKeyEquivalent:@"\r"];
	[okButton setAutoresizingMask:NSViewMaxYMargin | NSViewMinXMargin];
	
	
	NSRect cancelButtonFrame = NSMakeRect(okButtonFrame.origin.x - buttonXDistance- buttonWidth,
										  buttonBottomPadding,
										  buttonWidth, buttonHeight);
	NSButton *cancelButton = [[NSButton alloc] initWithFrame: cancelButtonFrame];
	[cancelButton setBezelStyle:NSRoundedBezelStyle];
	[cancelButton setTitle:@"Cancel"];
	[cancelButton setTarget:self];
	[cancelButton setAction:@selector(filesystemEditCancelClicked:)];
	[cancelButton setKeyEquivalent:@"\e"];
	[cancelButton setAutoresizingMask:NSViewMaxYMargin | NSViewMinXMargin];
	
	[outerView setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
	[outerView addSubview:cancelButton];
	[outerView addSubview:okButton];
	
	return outerView;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	MGTransitioningTabView *myTabView = (MGTransitioningTabView *)tabView;
	NSWindow *sheetWindow = [NSApp keyWindow];
	NSRect oldSheetFrame = [sheetWindow frame];
	NSSize oldTabViewSize = [tabView frame].size;
	CGFloat deltaX = [sheetWindow frame].size.width - oldTabViewSize.width;
	CGFloat deltaY = [sheetWindow frame].size.height - oldTabViewSize.height;
	NSSize newtabViewSize = [myTabView sizeWithTabviewItem: tabViewItem];
	NSSize newSize = NSMakeSize(newtabViewSize.width+deltaX, newtabViewSize.height+deltaY);
	[sheetWindow setFrame:NSMakeRect(oldSheetFrame.origin.x-0.5*(newSize.width-oldSheetFrame.size.width), 
									  oldSheetFrame.origin.y-(newSize.height-oldSheetFrame.size.height), 
									  newSize.width, newSize.height)
				  display:YES 
				  animate:YES];
}

@end
