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
#import "MFError.h"
#import "MFConstants.h"
#import <DiskArbitration/DiskArbitration.h>

#define FSDEF_EXTENSION @"macfusion"
#define RECENTS_PATH @"~/Library/Application Support/Macfusion/recents.plist"

@interface MFFilesystemController (PrivateAPI)
- (void)setUpVolumeMonitoring;
- (void)storeFilesystem:(MFServerFS*)fs 
			   withUUID:(NSString*)uuid;
- (void)removeFilesystem:(MFServerFS*)fs;
- (void)loadRecentFilesystems;
- (void)recordRecentFilesystem:(MFServerFS*)fs;

@property(readwrite, retain) NSMutableArray* filesystems;
@property(readwrite, retain) NSMutableArray* recents;
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
		recents = [NSMutableArray array];
		[self loadRecentFilesystems];
		[self setUpVolumeMonitoring];
		MFLogS(self, @"Init complete!");

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
			NSString* path = fs.mountPath;
			for(NSString* mountedPath in mountedPaths)
			{
				if ([path isEqualToString: mountedPath] &&
					[[self getUUIDXattrAtPath: mountedPath] isEqualToString: fs.uuid])
				{
					MFLogS(self, @"Premounth hit");
					[fs handleMountNotification];
				}
			}
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

- (MFServerFS*)quickMountWithURL:(NSURL*)url 
						   error:(NSError**)error
{
	MFServerPlugin* plugin = nil;
	for( MFServerPlugin* p in [[MFPluginController sharedController] plugins] )
	{
		if ([[[p delegate] urlSchemesHandled] containsObject: [url scheme]])
			plugin = p;
	}
	
	if (!plugin)
	{
		NSString* description = [NSString stringWithFormat: 
								 @"No plugin for URLs of type %@", [url scheme]];
		*error = [MFError errorWithErrorCode: kMFErrorCodeNoPluginFound
								 description: description ];
		return nil;
	}
	
	MFServerFS* fs = [MFServerFS filesystemFromURL: url
											plugin: plugin
											 error: error ];
	[self storeFilesystem: fs];
	[fs performSelector:@selector(mount) withObject:nil afterDelay:0];
	return fs;
}

#pragma mark Recents Managment

- (void)writeRecentFilesystems
{
	 NSString* recentsPath = [RECENTS_PATH stringByExpandingTildeInPath];
	 BOOL isDir;
	 if (![[NSFileManager defaultManager] fileExistsAtPath:[recentsPath stringByDeletingLastPathComponent]
											   isDirectory:&isDir] || !isDir)
	 {
		 NSError* error = nil;
		 BOOL ok = [[NSFileManager defaultManager] createDirectoryAtPath:recentsPath
											 withIntermediateDirectories:YES
															  attributes:nil
																   error:&error];
		 if (!ok)
		 {
			 MFLogS(self, @"Failed to create directory for writing recents: %@",
					[error localizedDescription]);
		 }
	 }
	
	BOOL writeOK = [recents writeToFile: recentsPath atomically:NO];
	if (!writeOK)
	{
		MFLogS(self, @"Could not write recents to file!");
	}
	
}

- (void)loadRecentFilesystems
{
	NSString* filePath = [RECENTS_PATH stringByExpandingTildeInPath];
	NSArray* recentsRead =[NSArray arrayWithContentsOfFile: filePath];
	[[self mutableArrayValueForKey:@"recents"] removeAllObjects];
	if (!recentsRead)
	{
		MFLogS(self, @"Could not read recents from file at path %@", filePath);
	}
	else
	{
		[[self mutableArrayValueForKey:@"recents"]
		 addObjectsFromArray: recentsRead];
	}
}

- (void)recordRecentFilesystem:(MFServerFS*)fs
{
	NSMutableDictionary* params = [fs.parameters mutableCopy];
	// Strip the UUID so it never repeats
	[params setValue:nil forKey:KMFFSUUIDParameter];
	
	for(NSDictionary* recent in recents)
	{
		BOOL equal = YES;
		for(NSString* key in [recent allKeys])
		{
			equal = ([[recent objectForKey:key] isEqual:
					  [params objectForKey:key]]);
			if (!equal)
				break;
		}
		if (equal) 
		{
			MFLogS(self, @"Duplicate recents detected, %@ and %@",
				   params, recent);
			return; // We already have this exact dictionary in recents. Don't add it.
		}
			
	}
	
	[[self mutableArrayValueForKey:@"recents"]
	 addObject: params];
	if([recents count] > 10)
		[recents removeObjectAtIndex: 0];
	[self writeRecentFilesystems];
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
	
	// Make the evenets go through
	CFRunLoopRunInMode( kCFRunLoopDefaultMode, 1, YES );
}

- (void)updateStatusForFilesystem:(MFServerFS*)fs
{
	if ([mountedPaths containsObject: fs.mountPath])
		[fs handleMountNotification];
}

# pragma mark Self-monitoring
- (void)registerObservationOnFilesystem:(MFServerFS*)fs
{
	[fs addObserver:self
		 forKeyPath:@"status"
			options:NSKeyValueObservingOptionNew
			context:nil];
}

- (void)unregisterObservationOnFilesystem:(MFServerFS*)fs
{
	[fs removeObserver:self
			forKeyPath:@"status"];
}

- (void) observeValueForKeyPath:(NSString *)keyPath 
					   ofObject:(id)object 
						 change:(NSDictionary *)change 
						context:(void *)context
{
//	NSLog(@"MFFilesystemController observes: keypath %@, object %@, change %@",
//		  keyPath, object, change);
	NSString* newStatus = [change objectForKey:NSKeyValueChangeNewKey];
	MFServerFS* fs = object;
	
	// Remove temporarily filesystems if they fail to mount
	if ([newStatus isEqualToString: kMFStatusFSFailed] && ![fs isPersistent])
		[self performSelector:@selector(removeFilesystem:) withObject:fs afterDelay:0];
}

# pragma mark Accessors and Getters

- (void)storeFilesystem:(MFServerFS*)fs 
{
	NSAssert(fs && fs.uuid, @"FS or uuid is nil, storeFilesystem in MFFilesystemController");
	[filesystemsDictionary setObject: fs
							  forKey: fs.uuid];
	if ([filesystems indexOfObject:fs] == NSNotFound)
	{
		[[self mutableArrayValueForKey:@"filesystems"] addObject: fs];
		[self registerObservationOnFilesystem: fs];
	}
}

- (void)removeFilesystem:(MFServerFS*)fs
{
	NSAssert(fs, @"Asked to remove nil fs in MFFilesystemController");
	[fs removeMountPoint];
	[filesystemsDictionary removeObjectForKey: fs.uuid];
	if ([filesystems indexOfObject:fs] != NSNotFound)
	{
		[[self mutableArrayValueForKey:@"filesystems"] removeObject: fs];
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

- (NSString*)getUUIDXattrAtPath:(NSString*)path
{
	NSString* resultString = nil;
	char* dataBuffer = malloc(100 * sizeof(char));
	int result = getxattr([path cStringUsingEncoding: NSUTF8StringEncoding],
						  "org.mgorbach.macfusion.xattr.uuid", dataBuffer, 100*sizeof(char),
						  0, 0);
	if (result > 0)
		resultString = [NSString stringWithCString:dataBuffer length:result]; 
	free(dataBuffer);
	return resultString;
}

- (void)addMountedPath:(NSString*)path
{
//	MFLogS(self, @"Adding mounted path %@", path);
	NSAssert(path, @"Mounted Path nil in MFFilesystemControlled addMountedPath");
	if (![mountedPaths containsObject: path])
	{
		[mountedPaths addObject: path];
		for(MFServerFS* fs in filesystems)
		{
			if ([fs.mountPath isEqualToString: path] &&
				([fs isWaiting] ))
			{
				[fs handleMountNotification];
			}
			if (! [fs isPersistent] )
			{
				[self recordRecentFilesystem: fs];
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
		NSArray* matchingFilesystems = [filesystems filteredArrayUsingPredicate: 
										[NSPredicate predicateWithFormat:@"self.mountPath == %@", path]];
		[matchingFilesystems makeObjectsPerformSelector:@selector(handleUnmountNotification)];
		
		NSArray* matchingTemporaryFilesystems = [matchingFilesystems filteredArrayUsingPredicate:
												 [NSPredicate predicateWithFormat:@"self.isPersistent != YES"]];
		for(MFServerFS* fs in matchingTemporaryFilesystems)
			[self removeFilesystem: fs];
	}
}

@synthesize filesystems, recents;

@end 