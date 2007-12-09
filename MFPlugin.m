//
//  MFPlugin.m
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFPlugin.h"


@implementation MFPlugin
+ (MFPlugin*)pluginFromBundleAtPath:(NSString*)path
{
	
	MFPlugin* plugin = nil;
	NSBundle* b = [NSBundle bundleWithPath:path];
	NSString* pluginClassName = [b objectForInfoDictionaryKey:@"MFPluginClass"];
	if (pluginClassName == nil || [pluginClassName isEqualToString:@"MFPlugin"])
	{
		plugin = [[MFPlugin alloc] initWithPath:path];
	}
	else
	{
		BOOL success = [b load];
		if (success)
		{
			Class PluginClass = NSClassFromString(pluginClassName);
			plugin = [[PluginClass alloc] initWithPath:path];
		}
		else
		{
			MFLog(@"Failed to load bundle for plugin at path %@", path);
		}
	}
	
	return plugin;
}

- (MFPlugin*)initWithPath:(NSString*)path
{
	self = [self init];
	NSBundle* b = [NSBundle bundleWithPath:path];
	bundle = b;
	NSString* plistPath = [b objectForInfoDictionaryKey:@"MFPluginPlist"];
	dictionary = [NSMutableDictionary dictionaryWithContentsOfFile: [b pathForResource:plistPath ofType:nil]];
	if (!dictionary)
	{
		// Failed to read from plist
		return nil;
	}
	
	[dictionary setObject: [b objectForInfoDictionaryKey:@"CFBundleIdentifier"] forKey:@"BundleIdentifier"];
	return self;
}

- (id)defaultValueForParameter:(NSString*)parameterName
{
	return nil;
}

- (void)fillDefaultsDictionary:(NSMutableDictionary*)defaultsDictionary fromParameterDescription:(NSDictionary*)parametersDict
{
	for(NSString* parameterKey in [parametersDict keyEnumerator])
	{
		NSDictionary* parameterDict = [parametersDict objectForKey:parameterKey];
		id defaultValueForParam = [self defaultValueForParameter: parameterKey];
		if (!defaultValueForParam)
		{
			defaultValueForParam = [parameterDict objectForKey:@"Default Value"];
		}
		
		if (defaultValueForParam)
		{
			[defaultsDictionary setObject:defaultValueForParam 
								   forKey:parameterKey];
		}
		else
		{
			MFLogS(self, @"Can not get a default value for parameter: %@",
				   parameterKey);
		}
	}
}

- (NSDictionary*)defaultParameterDictionary
{
	NSMutableDictionary* defaultsDictionary = [NSMutableDictionary dictionary];
	NSDictionary* parametersDict = [dictionary objectForKey:@"Parameters"];
	[self fillDefaultsDictionary:defaultsDictionary fromParameterDescription:parametersDict];
	
	// Add in parameters common across all FUSE filesystems
	NSBundle* searchBundle  = [NSBundle bundleForClass: [MFPlugin class]];
	MFLog(@"Bundle to search %@", searchBundle);
	NSString* fusePlistPath = [searchBundle pathForResource:@"fuse" ofType:@"plist"];
	NSDictionary* fusePlist = [NSDictionary dictionaryWithContentsOfFile:fusePlistPath];
	NSDictionary* fuseParams = [fusePlist objectForKey:@"Parameters"];
	if (fuseParams)
	{
		[self fillDefaultsDictionary:defaultsDictionary
			fromParameterDescription:fuseParams];
	}
	else
	{
		MFLogS(@"Can not read parameters from FUSE dictionary");
	}
	
	return defaultsDictionary;
}

- (NSString*)tokenForParameter:(NSString*)param
{
	NSDictionary* parametersDict = [dictionary objectForKey:@"Parameters"];
	NSDictionary* paramDict = [parametersDict objectForKey:param];
	NSString* token;
	token = [paramDict objectForKey:@"Token"];
	return token;
}

- (NSString*)inputFormatString
{
	return [[self dictionary] objectForKey:@"Input Format"];
}

- (NSString*)taskPath
{
	NSArray* locationsArray = [dictionary objectForKey:@"Binary Location"];
	NSFileManager* fm = [NSFileManager defaultManager];
	for(NSString* path in locationsArray)
	{
		if ([path isAbsolutePath])
		{
			if ([fm fileExistsAtPath:path])
			{
				return path;
			}
		}
		else
		{
			NSString* fullPath;
			if ((fullPath = [bundle pathForResource:path ofType:nil]) != nil)
			{
				return fullPath;
			}
		}
	}
	
	// We can't find the executable
	return nil;
}

- (NSString*)ID
{
	return [self.dictionary objectForKey: @"BundleIdentifier"];
}

@synthesize dictionary, bundle;
@end
