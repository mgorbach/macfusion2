//
//  MFQuickMountController.h
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
#import "MFClientFSDelegateProtocol.h";

@class MFClientFS, MFClient;

@interface MFQuickMountController : NSWindowController <MFClientFSDelegateProtocol> 
{
	
	IBOutlet NSTextField* qmTextField;
	IBOutlet NSTableView* recentsTableView;
	IBOutlet NSArrayController* recentsArrayController;
	IBOutlet NSProgressIndicator* indicator;
	IBOutlet NSButton* connectButton;
	
	MFClientFS* fs;
	MFClient* client;
}

- (IBAction)quickMount:(id)sender;
- (IBAction)recentClicked:(id)sender;

@property(readonly, retain) MFClient* client;
@end
