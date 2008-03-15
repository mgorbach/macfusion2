//
//  MFCommunicationServer.m
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

#import "MFCommunicationServer.h"
#import "MFFilesystemController.h"
#import "MFFilesystem.h"
#import "MFPluginController.h"
#import "MFConstants.h"
#import "MFPreferences.h"

@implementation MFCommunicationServer
static MFCommunicationServer* sharedServer = nil;


+ (MFCommunicationServer*)sharedServer
{
	if (sharedServer == nil)
	{
		[[self alloc] init];
	}
	
	return sharedServer;
}

+ (MFCommunicationServer*)allocWithZone:(NSZone*)zone
{
	if (sharedServer == nil)
	{
		sharedServer = [super allocWithZone: zone];
		return sharedServer;
	}
	
	return nil;
}

- (void)registerNotifications
{
	NSArray* filesystems = [[self filesystemController] filesystems];
	NSIndexSet* indexes = [NSIndexSet indexSetWithIndexesInRange: 
						  NSMakeRange(0, [filesystems count])];
	[filesystems addObserver:self
		  toObjectsAtIndexes:indexes
				  forKeyPath:@"status"
					 options:NSKeyValueObservingOptionNew
					 context:nil];
	[filesystems addObserver:self
		  toObjectsAtIndexes:indexes
				  forKeyPath:@"parameters"
					 options:NSKeyValueObservingOptionNew
					 context:nil];
	
	[[MFFilesystemController sharedController] addObserver: self
												forKeyPath: @"filesystems"
												   options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
												   context: nil];
	[[MFFilesystemController sharedController] addObserver: self
												forKeyPath: @"plugins"
												   options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
												   context: nil];
	[[MFFilesystemController sharedController] addObserver: self
												forKeyPath: @"recents"
												   options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
												   context: nil];
}

- (id) init
{
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (void)vendDisributedObject
{
	NSConnection* connection = [NSConnection defaultConnection];
	// TODO: Vend a proxy to set up protocol instead of, um , everything
	[connection setRootObject:self];
	if ([connection registerName:kMFDistributedObjectName] == YES)
	{
	}
	else
	{
		MFLogS(self, @"Failed to register connection name");
		exit(-1);
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath 
					   ofObject:(id)object
						 change:(NSDictionary *)change
						context:(void *)context
{
	NSDistributedNotificationCenter* dnc = [NSDistributedNotificationCenter defaultCenter];
	
	// MFLogS(self, @"Observes: keypath %@ object %@, change %@", keyPath, object, change);
	
	if ([keyPath isEqualToString:@"status"] && [object isKindOfClass: [MFFilesystem class]])
	{
		MFFilesystem* fs = (MFFilesystem*)object;
		NSDictionary* userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys: 
									  fs.uuid, KMFFSUUIDParameter,
									  fs.status, kMFSTStatusKey,
									  nil];
		[dnc postNotificationName:kMFStatusChangedNotification
						   object:kMFDNCObject
						 userInfo:userInfoDict
			  deliverImmediately:YES];
	}
	
	if ([keyPath isEqualToString:@"filesystems"] && object == [MFFilesystemController sharedController])
	{
		NSUInteger changeKind = [[change objectForKey: NSKeyValueChangeKindKey] intValue];
		if(changeKind == NSKeyValueChangeInsertion)
		{
			for (MFServerFS* fs in [change objectForKey: NSKeyValueChangeNewKey])
			{
				[fs addObserver:self
					 forKeyPath:@"status"
						options:NSKeyValueObservingOptionNew
						context:nil];
				[fs addObserver:self
					 forKeyPath:@"parameters"
						options:NSKeyValueObservingOptionNew
						context:nil];

				NSDictionary* userInfoDict = [NSDictionary dictionaryWithObject: [fs uuid]
																		 forKey: KMFFSUUIDParameter];
				[dnc postNotificationName:kMFFilesystemAddedNotification
								   object:kMFDNCObject
								 userInfo:userInfoDict];
			}
		}
		
		if(changeKind == NSKeyValueChangeRemoval)
		{
			for(MFServerFS* fs in [change objectForKey: NSKeyValueChangeOldKey])
			{
				[fs removeObserver: self
						forKeyPath:@"status"];
				[fs removeObserver: self
						forKeyPath:@"parameters"];
				NSDictionary* userInfoDict = [NSDictionary dictionaryWithObject: [fs uuid]
																		forKey: KMFFSUUIDParameter ];
				[dnc postNotificationName:kMFFilesystemRemovedNotification
								   object:kMFDNCObject
								 userInfo:userInfoDict];
			}
		}
	}
	
	if ([keyPath isEqualToString:@"recents"] && object == [MFFilesystemController sharedController])
	{
		NSUInteger changeKind = [[change objectForKey: NSKeyValueChangeKindKey] intValue];
		if (changeKind == NSKeyValueChangeInsertion)
		{
			NSArray*  newRecent = [change objectForKey:NSKeyValueChangeNewKey];
			NSDictionary* userInfoDict = [NSDictionary dictionaryWithObject:[newRecent objectAtIndex:0]
																	 forKey:kMFRecentKey];
			[dnc postNotificationName:kMFRecentsUpdatedNotification
							   object:kMFDNCObject
							 userInfo:userInfoDict ];
		}
	}
}

- (NSArray*)recents
{
	return [[MFFilesystemController sharedController] recents];
}

- (MFFilesystemController*)filesystemController
{
	return [MFFilesystemController sharedController];
}

- (MFPluginController*)pluginController
{
	return [MFPluginController sharedController];
}

- (void)doInitializationComplete:(NSTimer*)timer
{
	// MFLogS(self, @"Timer complete");
	if ([[MFPreferences sharedPreferences] getBoolForPreference: kMFPrefsAutoloadMenuling])
	{
		[[NSWorkspace sharedWorkspace] launchApplication: (NSString*)mfcMenulingBundlePath()];
	}
}

- (void)startServingRunloop
{
	[self registerNotifications];
	[self vendDisributedObject];
	NSTimer* timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(doInitializationComplete:)
										   userInfo:nil repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] run];
}


# pragma mark Action Methods
- (MFServerFS*)newFilesystemWithPluginName:(NSString*)pluginName
{
	NSAssert(pluginName, @"MFCommunicationServer: Asked for new filesystem with nil plugin name");
	MFServerPlugin* plugin = [[[MFPluginController sharedController] pluginsDictionary]
						objectForKey:pluginName];
	NSAssert(plugin, @"MFCommunicationServer: Asked for FS with invalid plugin name");
	MFServerFS* fs = [[MFFilesystemController sharedController] 
						  newFilesystemWithPlugin: plugin];
	return fs;
}
				 
- (MFServerFS*)filesystemWithUUID:(NSString*)uuid
{
	NSAssert(uuid, @"Filesystem requested with nil uuid in server");
	return [[MFFilesystemController sharedController] filesystemWithUUID:uuid];
}

- (MFServerFS*)quickMountWithURL:(NSURL*)url
{
	NSError* error;
	MFServerFS* fs = [[MFFilesystemController sharedController] quickMountWithURL: url error:&error];
	if (error)
		recentError = error;
	return fs;
}
				 
- (void)deleteFilesystemWithUUID:(NSString*)uuid
{
	MFServerFS* fs = [[MFFilesystemController sharedController] filesystemWithUUID: uuid];
	NSAssert(fs, @"CommunicationServer asked to remove filesystem with bad uuid");
	[[MFFilesystemController sharedController] deleteFilesystem: fs];
}

#pragma mark Security Tokens
- (NSString*)tokenForFilesystemWithUUID:(NSString*)uuid
{
	MFServerFS* fs = [[MFFilesystemController sharedController] filesystemWithUUID: uuid];
	return [[MFFilesystemController sharedController] tokenForFilesystem: fs];
}

- (MFServerFS*)filesystemForToken:(NSString*)token
{
	MFServerFS* fs = [[MFFilesystemController sharedController] filesystemForToken: token];
	if (fs)
		[[MFFilesystemController sharedController] invalidateToken: token];
	return fs;
}

#pragma mark Sever Protocol Methods
- (NSArray*)filesystems
{
	return [[MFFilesystemController sharedController] filesystems];
}

- (NSArray*)plugins
{
	return [[MFPluginController sharedController] plugins];
}

- (NSError*)recentError
{
	return recentError;
}

@end
