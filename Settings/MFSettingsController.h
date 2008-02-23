//
//  MFSettingsController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 1/16/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MFClient;

@interface MFSettingsController : NSObject {
	IBOutlet NSArrayController* filesystemArrayController;
	IBOutlet NSArrayController* pluginArrayController;
	IBOutlet NSTableView* filesystemTableView;
	IBOutlet NSBox* configurationViewBox;
	IBOutlet NSPopUpButton* button;
	IBOutlet NSCollectionView* filesystemCollectionView;
	IBOutlet NSButton* mountButton;
	
	
	NSViewController* filesystemConfigurationViewController;
	MFClient* client;
}

- (IBAction)popupButtonClicked:(id)sender;
- (IBAction)editSelectedFilesystem:(id)sender;
- (IBAction)mountSelectedFilesystem:(id)sender;

@property(readonly) MFClient* client;
@end
