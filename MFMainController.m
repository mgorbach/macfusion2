//
//  MFMainController.m
//  Macfusion2
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

#import "MFMainController.h"
#import "MFPlugin.h"
#import "MFPluginController.h"
#import "MFFilesystemController.h"
#import "MFFilesystem.h"
#import "MFCommunicationServer.h"
#include <sys/xattr.h>
#import "MFLogging.h"
#import "MFConstants.h"

@implementation MFMainController
static MFMainController* sharedController = nil;

#pragma mark Singleton Methods
+ (MFMainController*)sharedController
{
	if (sharedController == nil)
	{
		[[self alloc] init];
	}
	
	return sharedController;
}

+ (id)allocWithZone:(NSZone*) zone
{
	if (sharedController == nil)
	{
		sharedController = [super allocWithZone:zone];
		return sharedController;
	}
	
	return nil;
}

- (id)copyWithZone:(NSZone*)zone
{
	return self;
}

#pragma mark Runloop and initialization methods

- (void)startRunloop
{
	NSRunLoop* runloop = [NSRunLoop currentRunLoop];
	[runloop run];
}

- (void)initialize
{
	MFPluginController* pluginController = [MFPluginController sharedController];
	MFFilesystemController* filesystemController = [MFFilesystemController sharedController];
	[pluginController loadPlugins];
	[filesystemController loadFilesystems];
	[[MFCommunicationServer sharedServer] startServingRunloop];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self initialize];
}

# pragma mark Opening Files
- (BOOL)application:(NSApplication *)theApplication 
		   openFile:(NSString *)filePath
{
	NSDictionary* fileDict = [NSDictionary dictionaryWithContentsOfFile: filePath];
	NSString* uuid = [fileDict objectForKey: KMFFSUUIDParameter];
	if (!uuid)
	{
		MFLogS(self, @"Asked to open bad file at pah %@", filePath);
		return NO;
	}
	
	MFServerFS* fs = [[MFFilesystemController sharedController] filesystemWithUUID: uuid];
	if (!fs)
	{
		MFLogS(self, @"Can not find filesystem references at by file with uuid %@", uuid);
		return NO;
	}

	if ([fs isMounted])
	{
		[[NSWorkspace sharedWorkspace] selectFile:nil
						 inFileViewerRootedAtPath:[fs mountPath]];
	}
	else if ([fs isUnmounted] || [fs isFailedToMount])
	{
		[fs mount];
	}
	
	return YES;
}



@end
