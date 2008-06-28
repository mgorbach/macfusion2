//
//  MFPreferencesController.h
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

#import <Cocoa/Cocoa.h>
@class MFClient, MFPreferences;

@interface MFPreferencesController : NSWindowController {
	IBOutlet NSButton* agentLoginItemButton;
	IBOutlet NSButton* menuLoginItemButton;
	MFClient* client;
	MFPreferences* sharedPreferences;
	NSMapTable* prefsViewSizes;
	NSView* emptyView;
	
	IBOutlet NSTextField* fuseVersionTextField;
	IBOutlet NSView* pluginPrefsView;
	IBOutlet NSView* generalPrefsView;
}

- (IBAction)loginItemCheckboxChanged:(id)sender;
- (IBAction)toolbarItemChanged:(id)sender;

@end
