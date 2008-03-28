/*
 *  MFServerProtocol.h
 *  MacFusion2
 */

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

#import "MFClientPlugin.h"
#import "MFClientProtocol.h"

@class MFPluginController, MFFilesystemController, MFServerFS;

@protocol MFServerProtocol <NSObject>

// Accessors
- (NSArray*)filesystems;
- (NSArray*)plugins;
- (NSError*)recentError;
- (NSArray*)recents;

// Actions
- (MFServerFS*)newFilesystemWithPluginName:(NSString*)pluginName;
- (void)deleteFilesystemWithUUID:(NSString*)uuid;
- (MFServerFS*)filesystemWithUUID:(NSString*)uuid;
- (MFServerFS*)quickMountWithURL:(NSURL*)url;

//Security
- (NSString*)tokenForFilesystemWithUUID:(NSString*)uuid;
- (MFServerFS*)filesystemForToken:(NSString*)token;

// Client Control
- (void)registerClient:(id <MFClientProtocol>) client;
- (void)unregisterClient:(id <MFClientProtocol>) client;

// Logging
- (void)sendASLMessageDict:(NSDictionary*)dict;

@end


