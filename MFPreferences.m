//
//  MFPreferences.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MFPreferences.h"
#define PREFS_FILE_PATH @"~/Library/Application Support/Macfusion/preferences.plist"

@interface MFPreferences(PrivateAPI)
- (void)writePrefs;
@end

@implementation MFPreferences

static MFPreferences* sharedPreferences = nil;

+ (MFPreferences*) sharedPreferences
{
	if (sharedPreferences == nil)
		[[self alloc] init];
	
	return sharedPreferences;
}

+ (id)allocWithZone:(NSZone*)zone
{
	if (sharedPreferences == nil)
	{
		sharedPreferences = [super allocWithZone:zone];
		return sharedPreferences;
	}
	
	return nil;
}

- (void)init
{
	NSString* fullPrefsFilePath = [PREFS_FILE_PATH stringByExpandingTildeInPath];
	NSDictionary* readFromDisk = [NSDictionary dictionaryWithContentsOfFile: fullPrefsFilePath];
	if (!readFromDisk)
		firstTimeRun = YES;
	prefsDict = readFromDisk ? [readFromDisk mutableCopy] : [NSMutableDictionary dictionary];
//	MFLogS(self, @"Loaded prefs dict %@", prefsDict);
}

- (BOOL)firstTimeRun
{
	return firstTimeRun;
}

- (void)setValue:(id)value 
   forPreference:(NSString*)prefKey
{
	if (value != [self getValueForPreference:prefKey])
	{
		[prefsDict setObject: value
					  forKey: prefKey ];
		[self writePrefs];
	}
}

- (id)getValueForPreference:(NSString*)prefKey
{
	return [prefsDict objectForKey: prefKey];
}

- (void)writePrefs
{
	NSString* fullPrefsFilePath = [PREFS_FILE_PATH stringByExpandingTildeInPath];
	NSString* dirPath = [fullPrefsFilePath stringByDeletingLastPathComponent];
	BOOL isDir;
	if (! ([[NSFileManager defaultManager] fileExistsAtPath: dirPath isDirectory:&isDir] && isDir) )
	{
		NSError* dirCreateError;
		BOOL dirCreateOK = [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
								  withIntermediateDirectories:YES
												   attributes:nil
														error:&dirCreateError];
		if (!dirCreateOK)
		{
			MFLogS(self, @"Failed to create dir for prefs. Error %@", dirCreateError);
			return;
		}
		
	}
	
	BOOL ok = [prefsDict writeToFile:fullPrefsFilePath atomically:YES];
	if (!ok)
	{
		MFLogS(self, @"Failed to write prefs");
	}
}

- (BOOL)getBoolForPreference:(NSString*)prefKey
{
	return [[self getValueForPreference: prefKey] boolValue];
}

- (void)setBool:(BOOL)value forPreference:(NSString*)prefKey
{
	[self setValue: [NSNumber numberWithBool: value]
	 forPreference: prefKey ];
}

@end
