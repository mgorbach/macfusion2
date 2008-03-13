//
//  MFPreferencesController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MFPreferencesController.h"
#import "MFCore.h"
#import "MFClient.h"

@implementation MFPreferencesController
- (id)initWithWindowNibName:(NSString*)name
{
	if (self = [super initWithWindowNibName: name])
	{
		// MFLogS(self, @"Preferences system initialized");
		client = [MFClient sharedClient];
	}
	
	return self;
}

- (void)awakeFromNib
{
	[[self window] center];
	[menuLoginItemButton setState: getStateForMenulingLoginItem()];
	[agentLoginItemButton setState: getStateForAgentLoginItem()];
	NSString* macfuseVersion = getMacFuseVersion();
	NSString* versionString = macfuseVersion ? [NSString stringWithFormat: @"MacFuse Version %@ Found", macfuseVersion] : @"MacFuse not Found!";
	[fuseVersionTextField setStringValue: versionString];
	 
}

- (IBAction)loginItemCheckboxChanged:(id)sender
{
	if (sender == agentLoginItemButton)
		setStateForAgentLoginItem([sender state]);
	else if (sender == menuLoginItemButton)
		setStateForMenulingLoginItem([sender state]);
	else
	{
		MFLogS(self, @"Invalid sender for loginItemCheckboxChanged");
	}
}

@end
