//
//  MFPluginController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 11/6/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFPluginController.h"
#import "MFPlugin.h"

#define PLUGIN_EXTENSION @"mfplugin"

@implementation MFPluginController
static MFPluginController* sharedController = nil;

#pragma mark Singleton Methods
@synthesize plugins;

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
	plugins = [[NSMutableDictionary alloc] init];
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
	NSLog(@"Plugins being loaded. Searching...");
	NSArray* pluginBundlePaths = [self pathsToPluginBundles];
	for(NSString* path in pluginBundlePaths)
	{
		// TODO: What if different version of the same plugin are located in multiple places?
		MFPlugin* newPlugin;
		if ([self validatePluginAtPath: path] && (newPlugin = [MFPlugin pluginFromBundleAtPath: path]))
		{
			[plugins setObject: newPlugin forKey: newPlugin.id];
			MFPrint(@"%@", plugins);
			MFPrint(@"Loaded plugin at path %@ OK", path);
			MFPrint(@"Name: %@", newPlugin.id);
		}
		else
		{
			NSLog(@"Failed to load plugin at path %@", path);
		}
	}
}

- (MFPlugin*)pluginWithID:(NSString*)ID
{
	return [[self plugins] objectForKey:@"ID"];
}

@end
