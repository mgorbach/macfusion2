//
//  MFPreferences.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/15/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFPreferences.h"
#import <Carbon/Carbon.h>

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

void prefsFSEventCallBack(ConstFSEventStreamRef streamRef, 
						  void *clientCallBackInfo, 
						  size_t numEvents, 
						  void *eventPaths, 
						  const FSEventStreamEventFlags eventFlags[], 
						  const FSEventStreamEventId eventIds[])
{
	MFLogS([MFPreferences sharedPreferences], 
		   @"Prefs update FSEvents callback received");
	[[MFPreferences sharedPreferences] readPrefsFromDisk];
}

- (void)init
{
	NSString* fullPrefsFilePath = [PREFS_FILE_PATH stringByExpandingTildeInPath];
	NSDictionary* readFromDisk = [NSDictionary dictionaryWithContentsOfFile: fullPrefsFilePath];
	if (!readFromDisk)
		firstTimeRun = YES;
	prefsDict = readFromDisk ? [readFromDisk mutableCopy] : [NSMutableDictionary dictionary];
	FSEventStreamRef eventStream = FSEventStreamCreate(NULL, prefsFSEventCallBack, NULL, 
													   (CFArrayRef)[NSArray arrayWithObject: [fullPrefsFilePath stringByDeletingLastPathComponent]],
													   kFSEventStreamEventIdSinceNow, 0, kFSEventStreamCreateFlagUseCFTypes);
	FSEventStreamScheduleWithRunLoop(eventStream, [[NSRunLoop currentRunLoop] getCFRunLoop],
									 kCFRunLoopDefaultMode);
	FSEventStreamStart(eventStream);
}

- (BOOL)firstTimeRun
{
	return firstTimeRun;
}

- (void)readPrefsFromDisk
{
	NSString* fullPrefsFilePath = [PREFS_FILE_PATH stringByExpandingTildeInPath];
	NSDictionary* readFromDisk = [NSDictionary dictionaryWithContentsOfFile: fullPrefsFilePath];
	for(NSString* key in [readFromDisk allKeys])
	{
		id diskValue = [readFromDisk objectForKey: key];
		if (! [diskValue isEqualTo: [self getValueForPreference: key]] )
			[self setValue:diskValue forPreference:key];
	}
}

- (void)setValue:(id)value 
   forPreference:(NSString*)prefKey
{
	MFLogS(self, @"Setting value %@ for key %@", value, prefKey);
	if (value != [self getValueForPreference:prefKey])
	{
		[self willChangeValueForKey: prefKey];
		[prefsDict setObject: value
					  forKey: prefKey ];
		[self didChangeValueForKey: prefKey];
		[self writePrefs];
	}
}

- (id)defaultValueForPrefKey:(NSString*)key
{
	if ([key isEqualToString: kMFPrefsAutoScrollLog])
		return [NSNumber numberWithBool: YES];
	if ([key isEqualToString: kMFPrefsTimeout])
		return [NSNumber numberWithFloat: 5.0];
	
	return nil;
}


- (id)getValueForPreference:(NSString*)prefKey
{
	id value = [prefsDict objectForKey: prefKey];
	if (value)
		return value;
	else
		return [self defaultValueForPrefKey: prefKey];
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

- (id)valueForUndefinedKey:(NSString*)key
{
	NSLog(@"Value being called");
	return [self getValueForPreference: key];
}

- (void)setValue:(id)value 
		  forUndefinedKey:(NSString*)key
{
	[self setValue: value
	 forPreference: key];
}

@end
