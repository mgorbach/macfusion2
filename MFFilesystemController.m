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
		filesystemsDictionary = [NSMutableDictionary dictionary];
		filesystems = [NSMutableArray array];
		mountedPaths = [NSMutableArray array];
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

		NSError* error;
		MFServerFS* fs = [MFServerFS loadFilesystemAtPath: fsPath 
													error: &error];
		if (fs)
		{
			[self storeFilesystem: fs ];
		}
		else
		{
			MFLogS(self, @"Failed to load FS. Error: %@", [error localizedDescription] );
		}
	}
}

#pragma mark Action methods
- (MFServerFS*)newFilesystemWithPlugin:(MFServerPlugin*)plugin
{
	MFServerFS* fs = [MFServerFS newFilesystemWithPlugin: plugin];
	if (fs)
	{
		[self storeFilesystem: fs ];
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
		[[MFFilesystemController sharedController] addMountedPath: path];
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
		[[MFFilesystemController sharedController] removeMountedPath: path];
	}
	
	CFRelease(description);
}

- (void)setUpVolumeMonitoring
{
	appearSession = DASessionCreate(kCFAllocatorDefault);
	disappearSession = DASessionCreate(kCFAllocatorDefault);
	
	DASessionScheduleWithRunLoop(appearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	DASessionScheduleWithRunLoop(disappearSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	
	DARegisterDiskAppearedCallback(appearSession, kDADiskDescriptionMatchVolumeMountable, diskMounted, self);
	DARegisterDiskDisappearedCallback(disappearSession, kDADiskDescriptionMatchVolumeMountable, diskUnMounted, self);	
}

- (void)updateStatusForFilesystem:(MFServerFS*)fs
{
	if ([mountedPaths containsObject: fs.mountPath])
		[fs handleMountNotification];
}

# pragma mark Accessors and Getters

- (void)storeFilesystem:(MFServerFS*)fs 
{
	NSLog(@"FS %@, UUID %@", fs, fs.uuid);
	NSAssert(fs && fs.uuid, @"FS or uuid is nil, storeFilesystem in MFFilesystemController");
	[filesystemsDictionary setObject: fs
							  forKey: fs.uuid];
	if ([filesystems indexOfObject:fs] == NSNotFound)
	{
		[self willChange:NSKeyValueChangeInsertion
		 valuesAtIndexes:[NSIndexSet indexSetWithIndex:[filesystems count]]
				  forKey:@"filesystems"];
		[filesystems addObject: fs];
		[self updateStatusForFilesystem: fs];
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

- (void)addMountedPath:(NSString*)path
{
	NSAssert(path, @"Mounted Path nil in MFFilesystemControlled addMountedPath");
	if (![mountedPaths containsObject: path])
	{
		[mountedPaths addObject: path];
		for(MFServerFS* fs in filesystems)
		{
			if ([fs.mountPath isEqualToString: path])
			{
				MFLogS( [MFFilesystemController sharedController],
					   @"Mounted callback matches %@", fs.mountPath );
				[fs handleMountNotification];
			}
		}
	}
}

- (void)removeMountedPath:(NSString*)path
{
	NSAssert(path, @"Mounted Path nil in MFFilesystemControlled removeMountedPath");
	if ([mountedPaths containsObject: path])
	{
		[mountedPaths removeObject: path];
		for(MFServerFS* fs in filesystems)
		{
			if ([fs.mountPath isEqualToString: path])
			{
				MFLogS( [MFFilesystemController sharedController],
					   @"Unmounted callback matches %@", fs.mountPath );
				[fs handleUnmountNotification];
			}
		}
	}
}

@end 