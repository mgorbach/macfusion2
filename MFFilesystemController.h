//
//  MFFilesystemController.h
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
@class MFServerFS, MFServerPlugin;

@interface MFFilesystemController : NSObject {
	NSMutableDictionary* filesystemsDictionary;
	NSMutableArray* filesystems;
	NSMutableArray* recents;
	NSMutableArray* mountedPaths;
	NSMutableDictionary* tokens;
	NSMutableDictionary* mountPathPersistenceCache;
	
	DASessionRef appearSession;
	DASessionRef disappearSession;
}

// Init
+ (MFFilesystemController*)sharedController;
- (void)loadFilesystems;


// Action methods
- (MFServerFS*)newFilesystemWithPlugin:(MFServerPlugin*)plugin;
- (MFServerFS*)quickMountWithURL:(NSURL*)url 
						   error:(NSError**)error;
- (void)deleteFilesystem:(MFServerFS*)fs;

- (MFServerFS*)filesystemWithUUID:(NSString*)uuid;

// Security Tokens
- (NSString*)tokenForFilesystem:(MFServerFS*)fs;
- (void)invalidateToken:(NSString*)token;
- (MFServerFS*)filesystemForToken:(NSString*)token;

// Accessors
- (NSDictionary*)filesystemsDictionary;
@property(readonly, retain) NSMutableArray* filesystems;
@property(readonly, retain) NSMutableArray* recents;
@end

