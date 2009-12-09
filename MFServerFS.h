//
//  MFServerFS.h
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
#import "MFServerPlugin.h"
#import "MFFSDelegateProtocol.h"
#import "MFServerFSProtocol.h"

@interface MFServerFS : MFFilesystem <MFServerFSProtocol> {
	NSTask *_task;
	MFServerPlugin *_plugin;
	BOOL _pauseTimeout;
	NSTimer *_timer;
}


// Server-specific initialization
+ (MFServerFS *)loadFilesystemAtPath:(NSString*)path 
							  error:(NSError**)error;

+ (MFServerFS *)newFilesystemWithPlugin:(MFServerPlugin*)plugin;

+ (MFServerFS *)filesystemFromURL:(NSURL*)url plugin:(MFServerPlugin*)p error:(NSError **)error;


// Notification handling
- (void)handleMountNotification;
- (void)handleUnmountNotification;

- (void)removeMountPoint;

// validate
- (BOOL)validateParametersWithError:(NSError**)error;

@property(retain) MFServerPlugin *plugin;
@property(assign, readwrite) BOOL pauseTimeout;
@end
