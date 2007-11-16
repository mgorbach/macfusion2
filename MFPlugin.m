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
	MFPlugin* plugin = [[MFPlugin alloc] initWithPath:path];
	return [plugin autorelease];
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

- (NSDictionary*)defaultParameterDictionary
{
	NSMutableDictionary* defaultsDictionary = [NSMutableDictionary dictionary];
	NSDictionary* parametersDict = [dictionary objectForKey:@"Parameters"];
	for(NSString* parameterKey in [parametersDict keyEnumerator])
	{
		NSDictionary* parameterDict = [parametersDict objectForKey:parameterKey];
		id defaultValueForParam = [parameterDict objectForKey:@"Default Value"];
		[defaultsDictionary setObject:defaultValueForParam 
							   forKey:parameterKey];
	}
	
	return defaultsDictionary;
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
	
	// We can't find the executablr
	return nil;
}

- (NSString*)id
{
	return [self.dictionary objectForKey: @"BundleIdentifier"];
}

@synthesize dictionary;
@end
