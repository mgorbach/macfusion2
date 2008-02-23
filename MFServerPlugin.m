//
//  MFServerPlugin.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/12/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFServerPlugin.h"
#import "MFPlugin.h"

@implementation MFServerPlugin
+ (MFServerPlugin*)pluginFromBundleAtPath:(NSString*)path
{
	
	MFServerPlugin* plugin = nil;
	plugin = [[MFServerPlugin alloc] initWithPath:path];
	
	return plugin;
}

- (MFPlugin*)initWithPath:(NSString*)path
{
	self = [super init];
	if (self != nil)
	{
		NSBundle* b = [NSBundle bundleWithPath:path];
		bundle = b;
		NSString* plistPath = [b objectForInfoDictionaryKey:@"MFPluginPlist"];
		dictionary = [NSMutableDictionary dictionaryWithContentsOfFile: [b pathForResource:plistPath ofType:nil]];
		if (!dictionary)
		{
			// Failed to read from plist
			return nil;
		}
		
		[dictionary setObject: [b objectForInfoDictionaryKey:@"CFBundleIdentifier"] 
					   forKey: @"BundleIdentifier"];
		
		delegate = [self setupDelegate];
		if(!delegate)
		{
			return nil;
		}
	}
	
	return self;
}


@end
