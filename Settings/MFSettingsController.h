//
//  MFSettingsController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 1/16/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFClientFSDelegateProtocol.h"

@class MFClient, MFClientFS, MFFilesystemTableView, MFPreferencesController;


@interface MFSettingsController : NSObject <MFClientFSDelegateProtocol> {
	IBOutlet NSArrayController* filesystemArrayController;
	IBOutlet NSArrayController* pluginArrayController;
	IBOutlet MFFilesystemTableView* filesystemTableView;
	IBOutlet NSBox* configurationViewBox;
	IBOutlet NSPopUpButton* button;
	IBOutlet NSButton* mountButton;
	
	NSMutableDictionary* filesystemConfigurationViewControllers;
	MFClient* client;
	MFClientFS* fsBeingEdited;
	MFPreferencesController* preferencesController;
	
	BOOL creatingNewFS;
}

- (IBAction)popupButtonClicked:(id)sender;
- (IBAction)showPreferences:(id)sender;

- (void)editFilesystem:(MFClientFS*)fs;
- (void)deleteFilesystem:(MFClientFS*)fs;
- (void)toggleMountOnFilesystem:(MFClientFS*)fs;


@property(readonly) MFClient* client;
@end
