//
//  MFClientFS.h
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
#import "MFFilesystem.h"
#import "MFServerFSProtocol.h"
#import "MFClientFSDelegateProtocol.h"

@class MFClientPlugin;

@interface MFClientFS : MFFilesystem {
	id<MFServerFSProtocol> remoteFilesystem;
	MFClientPlugin* plugin;
	
	// For Undo
	NSDictionary* backupParameters;
	NSDictionary* backupSecrets;
	
	BOOL isEditing;
	NSInteger displayOrder;
	id<MFClientFSDelegateProtocol> clientFSDelegate;
	
	// UI references
	NSArray* viewControllers;
	NSViewController* topViewController;
	NSView* editingTabView;
}

+ (MFClientFS*)clientFSWithRemoteFS:(id)remoteFS 
					   clientPlugin:(MFClientPlugin*)plugin;

- (id)initWithRemoteFS:(id)remoteFS 
		  clientPlugin:(MFClientPlugin*)p;

// Notification handling
- (void)noteStatusInfoChanged;
- (void)noteParametersChanged;
- (void)setPauseTimeout:(BOOL)p;

// Editing
- (NSError*)endEditingAndCommitChanges:(BOOL)commit;
- (void)beginEditing;
- (NSDictionary*)displayDictionary;

// UI
- (void)setIconImage:(NSImage*)image;

@property(readwrite, assign) NSInteger displayOrder;
@property(readwrite, retain) id<MFClientFSDelegateProtocol> clientFSDelegate; 
@property(readonly) NSImage* iconImage;
@end
