//
//  MFClient.h
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
#import "MFServerProtocol.h"

@class MFClientFS, MFClientPlugin, MFClientRecent;

@interface MFClient : NSObject {
	NSMutableDictionary* filesystemsDictionary;
	NSMutableArray* persistentFilesystems;
	NSMutableArray* temporaryFilesystems;
	NSMutableDictionary* pluginsDictionary;
	NSMutableArray* plugins;
	NSMutableArray* recents;
	id <MFServerProtocol> server;
	id delegate;
	bool triedBootstrap;
}

+ (MFClient*)sharedClient;
- (BOOL)setup;

// Action methods
- (MFClientFS*)newFilesystemWithPlugin:(MFClientPlugin*)plugin;
- (MFClientFS*)quickMountFilesystemWithURL:(NSURL*)url
									 error:(NSError**)error;
- (MFClientFS*)mountRecent:(MFClientRecent*)recent
					 error:(NSError**)error;
- (void)deleteFilesystem:(MFClientFS*)fs;

// Accessors
- (MFClientFS*)filesystemWithUUID:(NSString*)uuid;
- (MFClientPlugin*)pluginWithID:(NSString*)id;

@property(retain) id delegate;

// All filesystems, including temporary ones
@property(readonly) NSArray* filesystems;

// Only filesystems that are not temporary
@property(readonly) NSArray* persistentFilesystems;
@property(readonly) NSArray* temporaryFilesystems;
@property(readonly) NSArray* mountedFilesystems;

// All plugins
@property (readonly) NSArray* plugins;
@property(readonly) NSArray* recents;

// UI Stuff
- (void)moveUUIDS:(NSArray*)uuid 
			toRow:(NSUInteger)row;
- (NSString*)createMountIconForFilesystem:(MFClientFS*)fs
								   atPath:(NSURL*)path;

@end
