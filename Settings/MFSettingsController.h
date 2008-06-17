//
//  MFSettingsController.h
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
#import "MFClientFSDelegateProtocol.h"

@class MFClient, MFClientFS, MFFilesystemTableView, MFPreferencesController,
MFLogViewerController, MGActionButton;


@interface MFSettingsController : NSObject <MFClientFSDelegateProtocol> 
{
	IBOutlet NSArrayController* filesystemArrayController;
	IBOutlet NSArrayController* pluginArrayController;
	IBOutlet MFFilesystemTableView* filesystemTableView;
	IBOutlet MGActionButton* newFSActionButton;
	
	MFClient* client;
	MFPreferencesController* preferencesController;
	MFLogViewerController* logViewerController;
}

- (IBAction)newFSPopupClicked:(id)sender;
- (IBAction)showPreferences:(id)sender;
- (IBAction)startMenuItem:(id)sender;
- (IBAction)showLogViewer:(id)sender;

- (IBAction)editSelectedFS:(id)sender;
- (IBAction)toggleSelectedFS:(id)sender;
- (IBAction)revealConfigForSelectedFS:(id)sender;
- (IBAction)revealSelectedFS:(id)sender;
- (IBAction)duplicateSelectedFS:(id)sender;
- (IBAction)deleteSelectedFS:(id)sender;
- (IBAction)filterLogForSelectedFS:(id)sender;

@property(readonly) MFClient* client;
@end
