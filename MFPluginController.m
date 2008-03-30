//
//  MFPluginController.m
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

#import "MFPluginController.h"
#import "MFServerPlugin.h"
#import "MFServerFS.h"
#import "MFCore.h"

#define PLUGIN_EXTENSION @"mfplugin"

@implementation MFPluginController
static MFPluginController* sharedController = nil;

#pragma mark Singleton Methods

+ (MFPluginController*)sharedController
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

- (MFPluginController*)init
{
	pluginsDictionary = [[NSMutableDictionary alloc] init];
	return self;
}

- (NSArray*)pathsToPluginBundles
{
	BOOL isDir = NO;
	NSFileManager* fm = [NSFileManager defaultManager];
	NSArray* libraryPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
															 NSAllDomainsMask - NSSystemDomainMask, YES);
	NSMutableArray* pluginSearchPaths = [NSMutableArray array];
	NSMutableArray* pluginPaths = [NSMutableArray array];
	
	for(NSString* path in libraryPaths)
	{
		NSString* specificPath = [path stringByAppendingPathComponent:@"Macfusion/Plugins"];
		if ([fm fileExistsAtPath:specificPath isDirectory:&isDir] && isDir)
		{
			[pluginSearchPaths addObject:specificPath];
		}
	}
	
	NSString* mainBundlePath = mfcMainBundlePath();
	MFLogS(self, @"Main bundle path  %@", mainBundlePath);
	NSBundle* mainBundle = [NSBundle bundleWithPath: mfcMainBundlePath()];
	NSString* pluginsPath = [mainBundle builtInPlugInsPath];
	if (pluginsPath)
		[pluginSearchPaths addObject: pluginsPath];
	for(NSString* path in pluginSearchPaths)
	{
		for(NSString* pluginPath in [fm directoryContentsAtPath:path])
		{
			if ([[pluginPath pathExtension] isEqualToString:PLUGIN_EXTENSION])
			{
				[pluginPaths addObject: [path stringByAppendingPathComponent: pluginPath]];
			}
		}
	}
	
	return [pluginPaths copy];
}

- (BOOL)validatePluginAtPath:(NSString*)path
{
	// TODO: Plugin validation goes here, or maybe this should go into 
	return YES;
}

- (void)loadPlugins
{
	NSArray* pluginBundlePaths = [self pathsToPluginBundles];
	for(NSString* path in pluginBundlePaths)
	{
		// TODO: What if different version of the same plugin are located in multiple places?
		MFServerPlugin* newPlugin;
		if ([self validatePluginAtPath: path] && 
			(newPlugin = [MFServerPlugin pluginFromBundleAtPath: path]))
		{
			[pluginsDictionary setObject: newPlugin forKey: newPlugin.ID];
			MFLogS(self, @"Loaded plugin at path %@ OK: %@", path, newPlugin.ID);
		}
		else
		{
			MFLogS(self, @"Failed to load plugin at path %@", path);
		}
	}
}

- (MFServerPlugin*)pluginWithID:(NSString*)ID
{
	return [pluginsDictionary objectForKey:ID];
}

- (MFServerPlugin*)pluginForFilesystem:(MFServerFS*)fs
{
	return [fs plugin];
}

- (NSArray*)plugins
{
	return [pluginsDictionary allValues];
}

- (NSDictionary*)pluginsDictionary
{
	return [pluginsDictionary copy];
}

@end
