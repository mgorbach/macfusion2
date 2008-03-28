//
//  MFLogViewerController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/24/08.
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

#import <Cocoa/Cocoa.h>
@class MFLogReader, MFClientFS;

@interface MFLogViewerController : NSWindowController {
	MFLogReader* logReader;
	IBOutlet NSTableView* logTableView;
	IBOutlet NSArrayController* logArrayController;
	IBOutlet NSPopUpButton* filesystemFilterPopup;
	IBOutlet NSButton* autoScrollButton;
	IBOutlet NSSearchField* logSearchField;
	
	NSInteger searchCategory;
	NSPredicate* filterPredicate;
	NSPredicate* searchPredicate;
}

- (IBAction)filterForFilesystem:(MFClientFS*)fs;
- (IBAction)searchCategoryChanged:(id)sender;


@property(readonly) NSPredicate* fullLogPredicate;
@property(readwrite, retain) NSPredicate* filterPredicate;
@property(readwrite, retain) NSPredicate* searchPredicate;

@end
