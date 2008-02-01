//
//  MFPluginController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 11/6/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFPluginController.h"
#import "MFServerPlugin.h"
#import "MFServerFS.h"

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
	MFLogS(self, @"Plugins being loaded. Searching...");
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
