//
//  MFPreferencesController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MFClient;

@interface MFPreferencesController : NSWindowController {
	IBOutlet NSButton* agentLoginItemButton;
	IBOutlet NSButton* menuLoginItemButton;
	MFClient* client;
	IBOutlet NSTextField* fuseVersionTextField;
}

- (IBAction)loginItemCheckboxChanged:(id)sender;

@end
