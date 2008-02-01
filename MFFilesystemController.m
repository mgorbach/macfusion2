//
//  MFFilesystemController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 11/7/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFFilesystemController.h"
#import "MFPluginController.h"
#import "MFServerPlugin.h"
#import "MFServerFS.h"
#import <DiskArbitration/DiskArbitration.h>

#define FSDEF_EXTENSION @"macfusion"

@interface MFFilesystemController (PrivateAPI)
- (void)setUpVolumeMonitoring;
- (void)storeFilesystem:(MFServerFS*)fs 
			   withUUID:(NSString*)uuid;
@end

@implementation MFFilesystemController

static MFFilesystemController* sharedController = nil;

#pragma mark Init and Singleton methods
+ (MFFilesystemController*)sharedController
{
	if (sharedController == nil)
	{
		[[self alloc] init];
	}
	
	return sharedController;
}

+ (MFFilesystemController*)allocWithZone:(NSZone*)zone
{
	if (sharedController == nil)
	{
		sharedController = [super allocWithZone: zone];
		return sharedController;
	}
	
	return nil;
}

- (void)registerGeneralNotifications
{
	/*
	NSDistributedNotificationCenter* dnc = [NSDistributedNotificationCenter defaultCenter];
	[dnc addObserver:self
			selector:@selector(handleMountNotification:)
				name:@"com.google.filesystems.fusefs.unotifications.mounted" 
			  object:@"com.google.filesystems.fusefs.unotifications"];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(handleUnmountNotification:)
															   name:NSWorkspaceDidUnmountNotification 
															 object:nil];
	 */
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		filesystemsDictionary = [[NSMutableDictionary alloc] init];
		filesystems = [NSMutableArray array];
		[self setUpVolumeMonitoring];
	}
	return self;
}

+ (NSSet*)keyPathsForValuesAffectingFilesystems
{
	return [NSSet setWithObjects: @"filesystemsDictionary", nil];
}

- (id)copyWithZone:(NSZone*)zone
{
	return self;
}

#pragma mark Filesystem loading
- (NSArray*)pathsToFilesystemDefs
{
	BOOL isDir = NO;
	NSFileManager* fm = [NSFileManager defaultManager];
	NSArray* libraryPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
																NSAllDomainsMask - NSSystemDomainMask, YES);
	NSMutableArray* fsDefSearchPaths = [NSMutableArray array];
	NSMutableArray* fsDefPaths = [NSMutableArray array];
	
	for(NSString* path in libraryPaths)
	{
		NSString* specificPath = [path stringByAppendingPathComponent:@"Macfusion/Filesystems/"];
		if ([fm fileExistsAtPath:specificPath isDirectory:&isDir] && isDir)
		{
			[fsDefSearchPaths addObject:specificPath];
		}
	}
	
	for(NSString* path in fsDefSearchPaths)
	{
		for(NSString* fsDefPath in [fm directoryContentsAtPath:path])
		{
			if ([[fsDefPath pathExtension] isEqualToString:FSDEF_EXTENSION])
			{
				[fsDefPaths addObject: [path stringByAppendingPathComponent: fsDefPath]];
			}
		}
	}
	
	return [fsDefPaths copy];
}

- (void)loadFilesystems
{
	MFLogS(self, @"Filesystems loading. Searching for filesystems.");
	NSArray* filesystemPaths = [self pathsToFilesystemDefs];
	for(NSString* fsPath in filesystemPaths)
	{
		MFLogS(self, @"Loading fs at %@", fsPath);
		NSDictionary* fsParams = [NSDictionary dictionaryWithContentsOfFile:fsPath];
		if (fsParams)
		{
			NSString* type = [fsParams objectForKey:@"Type"];
			MFServerPlugin* plugin = [[MFPluginController sharedController] pluginWithID: type];
			if (plugin)
			{
				MFServerFS* fs = [MFServerFS filesystemFromParameters:fsParams 
															   plugin:plugin];

				if (!fs)
				{
					MFLogS(self, @"Failed to load filesystem at path %@", fsPath);
				}
				
				if (YES)
				{
					[self storeFilesystem: fs
								 withUUID: fs.uuid];
					MFLogS(self, @"Filesystem loaded ok: %@", fs);
				}
				else
				{
					MFLogS(self, @"Failed to validate filesystem %@ on loading", fs);
				}
			}
			else
			{
				MFLogS(self, @"Failed to find plugin for filesystem at path %@",
					   fsPath);
			}
		}
		else
		{
			MFLogS(self, @"Unable to read filesystem dictionary at path %@",
				   fsPath);
		}
	}
}

#pragma mark Action methods
- (MFServerFS*)newFilesystemWithPlugin:(MFServerPlugin*)plugin
{
	NSDictionary* parameters = [NSDictionary dictionaryWithObject: plugin.ID
														   forKey:@"Type"];
	MFServerFS* fs = [MFServerFS filesystemFromParameters: parameters
													plugin: plugin];
	if (fs)
	{
		[self storeFilesystem: fs
					 withUUID: fs.uuid];
		return fs;
	}
	else
	{
		MFLogS(self, @"Failed to create new filesystem with plugin %@",
			   plugin);
		return nil;
	}
}

#pragma mark Volume monitoring

static void diskMounted(DADiskRef disk, void* mySelf) 
{
	CFDictionaryRef description = DADiskCopyDescription(disk);
	CFURLRef pathURL = CFDictionaryGetValue(description, kDADiskDescriptionVolumePathKey);
	
	if (pathURL)
	{
		CFStringRef tempPath = CFURLCopyFileSystemPath(pathURL,kCFURLPOSIXPathStyle);
		NSString* path = [(NSString*)tempPath stringByStandardizingPath];
		for(MFServerFS* fs in [[MFFilesystemController sharedController] filesystems])
		{
			if ([fs.mountPath isEqualToString: path])
			{
				MFLogS( [MFFilesystemController sharedController],
					   @"Mounted callback matches %@", fs.mountPath );
				[fs handleMountNotification];
			}
		}
	}
	
	CFRelease(description);
}


static void diskUnMounted(DADiskRef disk, void* mySelf)
{
	CFDictionaryRef description = DADiskCopyDescription(disk);
	CFURLRef pathURL = CFDictionaryGetValue(description, kDADiskDescriptionVolumePathKey);
	
	if (pathURL)
	{
		CFStringRef tempPath = CFURLCopyFileSystemPath(pathURL,kCFURLPOSIXPathStyle);
		NSString* path = [(NSString*)tempPath stringByStandardizingPath];
		for(MFServerFS* fs in [[MFFilesystemController sharedController] filesystems])
		{
			if ([fs.mountPath isEqualToString: path])
			{
				MFLogS( [MFFilesystemController sharedController],
					   @"Unmounted callback matches %@", fs.mountPath );
				[fs handleUnmountNotification];
			}
		}
	}
	
	CFRelease(description);
}

- (void) setUpVolumeMonitoring
{
	appearSession = DASessionCreate(kCFAllocatorDefault);
	disappearSession = DASessionCreate(kCFAllocatorDefault);
	
	DASessionScheduleWithRunLoop(appearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	DASessionScheduleWithRunLoop(disappearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	
	DARegisterDiskAppearedCallback(appearSession, kDADiskDescriptionMatchVolumeMountable, diskMounted, self);
	DARegisterDiskDisappearedCallback(disappearSession, kDADiskDescriptionMatchVolumeMountable, diskUnMounted, self);	
}

# pragma mark Accessors and Getters

- (void)storeFilesystem:(MFServerFS*)fs 
			   withUUID:(NSString*)uuid
{
	NSAssert(fs && uuid, @"FS or UUID is nill, storeFilesystem in MFFilesystemController");
	[filesystemsDictionary setObject: fs
							  forKey: uuid];
	if ([filesystems indexOfObject:fs] == NSNotFound)
	{
		[self willChange:NSKeyValueChangeInsertion
		 valuesAtIndexes:[NSIndexSet indexSetWithIndex:[filesystems count]]
				  forKey:@"filesystems"];
		[filesystems addObject: fs];
		[self didChange:NSKeyValueChangeInsertion
		 valuesAtIndexes:[NSIndexSet indexSetWithIndex:[filesystems count]]
				 forKey:@"filesystems"];
	}
}

- (void)removeFilesystem:(MFServerFS*)fs
{
	NSAssert(fs, @"Asked to remove nil fs in MFFilesystemController");
	[filesystemsDictionary removeObjectForKey: fs.uuid];
	if ([filesystems indexOfObject:fs] != NSNotFound)
	{
		[self willChange:NSKeyValueChangeRemoval
		 valuesAtIndexes:[filesystems objectAtIndex: [filesystems indexOfObject: fs]]
				  forKey:@"filesystems"];
		[filesystems removeObject:fs];
		[self didChange:NSKeyValueChangeRemoval
		 valuesAtIndexes:[filesystems objectAtIndex: [filesystems indexOfObject: fs]]
				  forKey:@"filesystems"];
	}
}

- (MFServerFS*)filesystemWithUUID:(NSString*)uuid
{
	NSAssert(uuid, @"UUID nill in filesystemWithUUID");
	return [filesystemsDictionary objectForKey:uuid];
}

- (NSDictionary*)filesystemsDictionary
{
	return (NSDictionary*)filesystemsDictionary;
}

- (NSArray*)filesystems
{
	return (NSArray*)filesystems;
}

@end 