//
//  MFPreferencesController.m
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

#import "MFPreferencesController.h"
#import "MFCore.h"
#import "MFClient.h"
#import "MFPreferences.h"

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
	[agentLoginItemButton setState: mfcGetStateForAgentLoginItem()];
	[menuLoginItemButton setState: [[MFPreferences sharedPreferences] getBoolForPreference: kMFPrefsAutoloadMenuling]];
	NSString* macfuseVersion = mfcGetMacFuseVersion();
	NSString* versionString = macfuseVersion ? [NSString stringWithFormat: @"MacFuse Version %@ Found", macfuseVersion] : @"MacFuse not Found!";
	[fuseVersionTextField setStringValue: versionString];
	 
}

- (IBAction)loginItemCheckboxChanged:(id)sender
{
	if (sender == agentLoginItemButton)
		mfcSetStateForAgentLoginItem([sender state]);
	else if (sender == menuLoginItemButton)
		[[MFPreferences sharedPreferences] setBool:[sender state]
									 forPreference:kMFPrefsAutoloadMenuling];
	else
	{
		MFLogS(self, @"Invalid sender for loginItemCheckboxChanged");
	}
}

@end
