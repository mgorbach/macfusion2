//
//  MFCommunicationServer.m
//  MacFusion2
//
//  Created by Michael Gorbach on 12/7/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFCommunicationServer.h"
#import "MFFilesystemController.h"
#import "MFFilesystem.h"
#import "MFPluginController.h"
#import "MFConstants.h"

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
		MFLogS(self, @"Now Vending distributed object");
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
	MFLogS(self, @"Observe triggered on keypath %@, object %@ change %@", keyPath, object, change);
	
	// TODO: This observation method will not be called on objects added to filesystems after registerNotifications is called
	// We need to observe filesystems itself, and add/remove observations on filesystems as they appear and dissapear
	NSDistributedNotificationCenter* dnc = [NSDistributedNotificationCenter defaultCenter];
	
	if ([keyPath isEqualToString:@"status"] && [object isKindOfClass: [MFFilesystem class]])
	{
		MFFilesystem* fs = (MFFilesystem*)object;
		NSDictionary* userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys: 
									  fs.uuid, kMFFilesystemUUIDKey,
									  fs.status, kMFFilesystemStatusKey,
									  nil];
		[dnc postNotificationName:kMFStatusChangedNotification
						   object:kMFDNCObject
						 userInfo:userInfoDict];
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
																		 forKey: kMFFilesystemUUIDKey];
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
			}
		}
	}
	
	
}

- (MFFilesystemController*)filesystemController
{
	return [MFFilesystemController sharedController];
}

- (MFPluginController*)pluginController
{
	return [MFPluginController sharedController];
}

- (void)startServingRunloop
{
	[self registerNotifications];
	[self vendDisributedObject];
	[[NSRunLoop currentRunLoop] run];
}


# pragma mark Action Methods
- (MFServerFS*)newFilesystemWithPluginName:(NSString*)pluginName
{
	MFServerPlugin* plugin = [[[MFPluginController sharedController] pluginsDictionary]
						objectForKey:pluginName];
	if (plugin)
	{
		MFServerFS* fs = [[MFFilesystemController sharedController] 
						  newFilesystemWithPlugin: plugin];
		return fs;
	}
	else
	{
		MFLogS(self, @"Request failed to create new filesystem. Now plugin named %@", 
			   pluginName);
		return nil;
	}
}
				 
- (MFServerFS*)filesystemWithUUID:(NSString*)uuid
{
	NSAssert(uuid, @"Filesystem requested with nil uuid in server");
	return [[MFFilesystemController sharedController] 
			filesystemWithUUID:uuid];
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

@end
