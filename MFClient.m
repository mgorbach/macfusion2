//
//  MFClient.m
//  MacFusion2
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MFClient.h"
#import "MFClientFS.h"
#import "MFClientPlugin.h"
#import "MFConstants.h"
#import "MFClientRecent.h"
#import <Security/Security.h>
#import "MFCore.h"

#define ORDERING_FILE_PATH @"~/Library/Application Support/Macfusion/Ordering.plist"

@interface MFClient(PrivateAPI)
- (void)storeFilesystem:(MFClientFS*)fs;
- (void)storePlugin:(MFClientPlugin*)plugin;
- (void)removeFilesystem:(MFClientFS*)fs;
- (void)loadOrdering;
- (void)setupKeychainMonitoring;
- (void)writeOrdering;
- (void)initializeIvars;
// Security monitoring

@property(readwrite, retain) NSMutableArray* persistentFilesystems;
@property(readwrite, retain) NSMutableArray* temporaryFilesystems;
@property(readwrite, retain) NSMutableArray* plugins;
@property(readwrite, retain) NSMutableArray* recents;
@end

@implementation MFClient

static MFClient* sharedClient = nil;

#pragma mark Singleton methods
+ (MFClient*)sharedClient
{
	if (sharedClient == nil)
	{
		[[self alloc] init];
	}
	
	return sharedClient;
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key
{
	if ([key isEqualToString:@"filesystems"]
		|| [key isEqualToString:@"mountedFilesystems"])
		return [NSSet setWithObjects:@"persistentFilesystems", @"temporaryFilesystems", nil];
	else
		return [super keyPathsForValuesAffectingValueForKey: key];
}


+ (MFClient*)allocWithZone:(NSZone*)zone
{
	if (sharedClient == nil)
	{
		sharedClient = [super allocWithZone: zone];
		return sharedClient;
	}
	
	return nil;
}

- (void)registerForGeneralNotifications
{
	NSDistributedNotificationCenter* dnc = [NSDistributedNotificationCenter 
											defaultCenter];
	[dnc addObserver:self
			selector:@selector(handleStatusChangedNotification:)
				name:kMFStatusChangedNotification
			  object:kMFDNCObject];
	[dnc addObserver:self
			selector:@selector(handleFilesystemAddedNotification:)
				name:kMFFilesystemAddedNotification 
			  object:kMFDNCObject];
	[dnc addObserver:self
			selector:@selector(handleFilesystemRemovedNotification:)
				name:kMFFilesystemRemovedNotification 
			  object:kMFDNCObject];
	[dnc addObserver:self
			selector:@selector(handleRecentsUpdatedNotification:)
				name:kMFRecentsUpdatedNotification 
			  object:kMFDNCObject];
	
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(handleApplicationTerminatingNotification:)
			   name:NSApplicationWillTerminateNotification
			 object:nil];

}

- (id) init
{
	self = [super init];
	if (self != nil) {
		[self registerForGeneralNotifications];
		[self initializeIvars];
		[self setupKeychainMonitoring];
	}
	return self;
}


- (void)initializeIvars
{
//	persistentFilesystems = [NSMutableArray array];
//	temporaryFilesystems = [NSMutableArray array];
	plugins = [NSMutableArray array];
	recents = [NSMutableArray array];
	persistentFilesystems = [NSMutableArray array];
	temporaryFilesystems = [NSMutableArray array];
}

- (void)fillInitialStatus
{
	// Reset everything
	[self initializeIvars];
	
	// Fill plugins
	NSArray* remotePlugins = [server plugins];
	NSArray* remoteFilesystems = [server filesystems];
	
	pluginsDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
	for(id remotePlugin in remotePlugins)
	{
		MFClientPlugin* plugin = [[MFClientPlugin alloc] initWithRemotePlugin: 
								  remotePlugin];
		if (plugin)
			[self storePlugin: plugin];
		else
			MFLogS(self, @"Could not init client plugin from server plugin %@", remotePlugin);
	}
	
	// Fill filesystems
	filesystemsDictionary = [NSMutableDictionary dictionaryWithCapacity:10];
	for(id remoteFS in remoteFilesystems)
	{
		MFClientPlugin* plugin = [pluginsDictionary objectForKey: [remoteFS pluginID]];
		MFClientFS* fs = [MFClientFS clientFSWithRemoteFS: remoteFS
											 clientPlugin: plugin];
		if (fs)
			[self storeFilesystem: fs];
		else
			MFLogSO(self, remoteFS, @"Could not init client fs from server fs %@", remoteFS);
	}
	
	// Fill Recents
	NSMutableArray* recentsFromServer = [[server recents] mutableCopy];
	for (NSDictionary* recent in recentsFromServer)
		[[self mutableArrayValueForKey:@"recents"] addObject:
		 [[MFClientRecent alloc] initWithParameterDictionary: recent]];
	[self loadOrdering];
}

- (BOOL)establishCommunication
{
	// Set up DO
	id serverObject = [NSConnection rootProxyForConnectionWithRegisteredName:kMFDistributedObjectName
																		host:nil];
	[serverObject setProtocolForProxy:@protocol(MFServerProtocol)];
	server = (id <MFServerProtocol>)serverObject;
	if (serverObject)
	{
		return YES;
	}
	else
	{
		return NO;
	}
}


#pragma mark Notification handling
- (void)handleStatusChangedNotification:(NSNotification*)note
{
	// MFLogS(self, @"Status change notification received %@", note);
	NSDictionary* info = [note userInfo];
	NSString* uuid = [info objectForKey: KMFFSUUIDParameter];
	MFClientFS* fs = [self filesystemWithUUID: uuid];
	[fs handleStatusInfoChangedNotification:note];
}

- (void)handleFilesystemAddedNotification:(NSNotification*)note
{
	NSDictionary* info = [note userInfo];
	NSString* uuid = [info objectForKey:  KMFFSUUIDParameter];
 
	id remoteFilesystem = [server filesystemWithUUID: uuid];
	if (![self filesystemWithUUID:uuid])
	{
		MFClientPlugin* plugin = [pluginsDictionary objectForKey: [remoteFilesystem pluginID]];
		MFClientFS* fs = [MFClientFS clientFSWithRemoteFS:remoteFilesystem
											 clientPlugin:plugin];
		
		[self storeFilesystem:fs ];
	}
}

- (void)handleFilesystemRemovedNotification:(NSNotification*)note
{
	NSDictionary* info = [note userInfo];
	NSString* uuid = [info objectForKey: KMFFSUUIDParameter];
	MFClientFS* fs = [self filesystemWithUUID: uuid];
	[self removeFilesystem:fs];
}

#pragma mark Action methods
- (MFClientFS*)newFilesystemWithPlugin:(MFClientPlugin*)plugin
{
	NSAssert(plugin, @"MFClient asked to make new filesystem with nil plugin");
	id newRemoteFS = [server newFilesystemWithPluginName: plugin.ID];
	MFClientFS* newFS = [[MFClientFS alloc]	initWithRemoteFS: newRemoteFS
												clientPlugin: plugin];
	[self storeFilesystem:newFS ];
	return newFS;
}

- (MFClientFS*)quickMountFilesystemWithURL:(NSURL*)url
									 error:(NSError**)error
{
	id remoteFS = [server quickMountWithURL:url];
	if (!remoteFS)
	{
		NSError* serverError = [server recentError];
		if (serverError)
			*error = serverError;
		return nil;
	}
	else
	{
		if ([self filesystemWithUUID:[remoteFS uuid]])
		{
			return [self filesystemWithUUID: [remoteFS uuid]];
		}
		
		MFClientPlugin* plugin = [self pluginWithID: [remoteFS pluginID]];
		MFClientFS* newFS = [[MFClientFS alloc] initWithRemoteFS: remoteFS
													clientPlugin: plugin ];
		[self storeFilesystem: newFS];
		return newFS;
	}
}

- (void)deleteFilesystem:(MFClientFS*)fs
{
	NSString* uuid = [fs uuid];
	[server deleteFilesystemWithUUID: uuid];
}

#pragma mark Recents
- (void)handleRecentsUpdatedNotification:(NSNotification*)note
{
	NSDictionary* recentParameterDict = [[note userInfo] objectForKey: kMFRecentKey ];
	[[self mutableArrayValueForKey:@"recents"] addObject: 
	 [[MFClientRecent alloc] initWithParameterDictionary: recentParameterDict ]];
	
	if ([[self recents] count] > 10)
		[[self mutableArrayValueForKey:@"recents"] removeObjectAtIndex: 0];
}

- (MFClientFS*)mountRecent:(MFClientRecent*)recent
					 error:(NSError**)error;
{
	NSURL* url = [NSURL URLWithString: recent.descriptionString];
	if (url)
	{
		MFClientFS* fs = [self quickMountFilesystemWithURL: url
									error: error ];
		if (fs)
			return fs;
	}
	
	return nil;
}

#pragma mark Security
OSStatus myKeychainCallback (
							 SecKeychainEvent keychainEvent,
							 SecKeychainCallbackInfo *info,
							 void *context
)
{
	MFClient* self = (MFClient*)context;
	// MFLogS(self, @"Keychain callback received event is %d", keychainEvent);
	SecKeychainItemRef itemRef = info -> item;
	NSString* uuid = (NSString*)mfsecUUIDForKeychainItemRef(itemRef);
	MFClientFS* fs = [self filesystemWithUUID:uuid];
	if (fs)
	{
		// MFLogS(self, @"Updating secrets for fs %@ due to keychain change", fs);
		[fs updateSecrets];
	}
	return 0;
}

- (void)setupKeychainMonitoring
{
	SecKeychainEventMask eventMask = kSecUpdateEventMask | kSecAddEventMask;
	SecKeychainAddCallback(myKeychainCallback , eventMask, self);
}

#pragma mark Accessors and Setters

- (NSArray*)filesystems
{
	NSMutableArray* filesystems = [NSMutableArray array];
	[filesystems addObjectsFromArray: temporaryFilesystems];
	[filesystems addObjectsFromArray: persistentFilesystems];
	return [filesystems copy];
}

- (NSArray*)mountedFilesystems
{
	return [self.filesystems filteredArrayUsingPredicate:
			[NSPredicate predicateWithFormat:@"self.isMounted == YES"]];
}

- (void)storePlugin:(MFClientPlugin*)plugin
{
	NSAssert(plugin && plugin.ID, @"plugin or ID null when storing plugin in MfClient");
	[pluginsDictionary setObject: plugin forKey: plugin.ID ];
	if ([plugins indexOfObject: plugin] == NSNotFound)
	{
		[[self mutableArrayValueForKey:@"plugins"]
		 addObject: plugin];
	}
}

- (void)storeFilesystem:(MFClientFS*)fs
{
	NSAssert(fs && fs.uuid, @"FS or fs.uuid is nil when storing fs in MFClient");
	[filesystemsDictionary setObject: fs
							  forKey: fs.uuid];
	if ([fs isPersistent] && [persistentFilesystems indexOfObject: fs] == NSNotFound)
	{
		[[self mutableArrayValueForKey:@"persistentFilesystems"] addObject: fs];
	}
	else if ( (![fs isPersistent]) && [temporaryFilesystems indexOfObject: fs] == NSNotFound)
	{
		[[self mutableArrayValueForKey:@"temporaryFilesystems"] addObject: fs];
	}
}

- (void)removeFilesystem:(MFClientFS*)fs
{
	NSAssert(fs, @"Asked to remove nil fs in MFClient");
	[filesystemsDictionary removeObjectForKey: fs.uuid];
	if ([fs isPersistent] && [persistentFilesystems indexOfObject: fs] != NSNotFound)
	{
		[[self mutableArrayValueForKey:@"persistentFilesystems"]
		 removeObject: fs];
	}
	else if (![fs isPersistent] && [temporaryFilesystems indexOfObject: fs] != NSNotFound)
	{
		[[self mutableArrayValueForKey:@"temporaryFilesystems"] removeObject: fs];
	}
}


- (MFClientFS*)filesystemWithUUID:(NSString*)uuid
{
	NSAssert(uuid, @"uuid nil when requesting FS in MFClient");
	return [filesystemsDictionary objectForKey:uuid];
}

- (MFClientPlugin*)pluginWithID:(NSString*)id
{
	NSAssert(id, @"id nil when requesting plugin in MFClient");
	return [pluginsDictionary objectForKey:id];
}

# pragma mark UI stuff
- (void)moveUUIDS:(NSArray*)uuids
			toRow:(NSUInteger)row
{
	NSMutableArray* filesystemsToInsert = [NSMutableArray array];
	NSMutableIndexSet* indexesToDelete = [NSMutableIndexSet indexSet];
	for(NSString* uuid in uuids)
	{
		MFClientFS* fs = [self filesystemWithUUID: uuid];
		if (fs && [fs isPersistent])
		{
			[filesystemsToInsert addObject: fs];
			[indexesToDelete addIndex: [persistentFilesystems indexOfObject:fs]];
		}
	}
	
	NSIndexSet* indexesToAdd = [NSIndexSet indexSetWithIndexesInRange: 
						  NSMakeRange(row, [filesystemsToInsert count])];
	BOOL lastRow = (row == [persistentFilesystems count]);
	
	if (lastRow)
	{
		[[self mutableArrayValueForKey:@"persistentFilesystems"] addObjectsFromArray: filesystemsToInsert];
		[[self mutableArrayValueForKey:@"persistentFilesystems"] removeObjectsAtIndexes:indexesToDelete];
	}
	else if ([indexesToAdd firstIndex] < [indexesToDelete firstIndex])
	{
		[[self mutableArrayValueForKey:@"persistentFilesystems"] removeObjectsAtIndexes:indexesToDelete];
		[[self mutableArrayValueForKey:@"persistentFilesystems"] insertObjects:filesystemsToInsert
																		 atIndexes:indexesToAdd];
	}
	else
	{
		[[self mutableArrayValueForKey:@"persistentFilesystems"] insertObjects:filesystemsToInsert
																		 atIndexes:indexesToAdd];
		[[self mutableArrayValueForKey:@"persistentFilesystems"] removeObjectsAtIndexes:indexesToDelete];
	}

	// Set the ordering correctly now
	for(MFClientFS* fs in persistentFilesystems)
	{
		[fs setDisplayOrder: [persistentFilesystems indexOfObject: fs]];
	}
	
	[self writeOrdering];
}

- (void)writeOrdering
{
	NSArray* uuidOrdering = [self.persistentFilesystems valueForKey: @"uuid"];
	NSString* fullPath = [ORDERING_FILE_PATH stringByExpandingTildeInPath];
	NSString* dirPath = [fullPath stringByDeletingLastPathComponent];
	[[NSFileManager defaultManager] createDirectoryAtPath: dirPath
							  withIntermediateDirectories:YES
											   attributes:nil
													error:NO];
	[uuidOrdering writeToFile: fullPath atomically:YES];
}

- (void)loadOrdering
{
	NSString* fullPath = [ORDERING_FILE_PATH stringByExpandingTildeInPath];
	NSArray* uuidOrdering = [NSArray arrayWithContentsOfFile: fullPath];
	if (uuidOrdering)
	{
		for(NSString* uuid in uuidOrdering)
			if ([self filesystemWithUUID: uuid])
				[[self filesystemWithUUID: uuid] setDisplayOrder: 
				 [uuidOrdering indexOfObject: uuid]];
	}
	
	[persistentFilesystems sortUsingDescriptors: 
	 [NSArray arrayWithObject: [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES]]];
}

- (void)handleApplicationTerminatingNotification:(NSNotification*)note
{
	// [self writeOrdering];
}

- (NSString*)createMountIconForFilesystem:(MFClientFS*)fs
								   atPath:(NSURL*)dirPathURL
{
	if (![fs isPersistent]) // We shouldn't be creating a mount icon for a non-persistent fs
		return nil;
	
	NSString* dirPath = [dirPathURL path];
	NSString* filename = [NSString stringWithFormat: @"%@.fusion", [fs name]];
	NSString* fullPath = [dirPath stringByAppendingPathComponent: filename];
	NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [fs uuid], KMFFSUUIDParameter, nil];
	[dict writeToFile: fullPath
		   atomically: YES];
	NSImage* iconImage = [NSImage imageNamed:@"macfusionIcon.icns"];
	[[NSWorkspace sharedWorkspace] setIcon: iconImage
								   forFile:fullPath
								   options:0];
	return filename;
}

@synthesize delegate, persistentFilesystems, temporaryFilesystems, plugins, recents;
@end
