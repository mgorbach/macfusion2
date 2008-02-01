//
//  MFClientFS.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/5/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFClientFS.h"
#import "MFConstants.h"
#import "MFClientPlugin.h"

@interface MFClientFS (PrivateAPI)
- (void)fillInitialData;
- (void)registerNotifications;
@end

@implementation MFClientFS

+ (MFClientFS*)clientFSWithRemoteFS:(id)remoteFS 
					   clientPlugin:(MFClientPlugin*)plugin
{
	MFClientFS* fs = nil;
	NSBundle* bundle = plugin.bundle;
	NSString* filesystemClassName = [bundle objectForInfoDictionaryKey:
									 @"MFClientFSClassName"];
	if (filesystemClassName == nil)
	{
		MFLogS(self, @"Failed to instantiate filesystem with remote fs %@. No Client Filesystem class specified.",
			   remoteFS);
	}
	else
	{
		BOOL success = [bundle load];
		if (success)
		{
			Class filesystemClass = NSClassFromString(filesystemClassName);
			if ([filesystemClass isSubclassOfClass: [MFClientFS class]])
			{
				fs = [[filesystemClass alloc] initWithRemoteFS: remoteFS 
												  clientPlugin: plugin];
			}
			else
			{
				MFLogS(self, @"Client filesystem class %@ is not a subclass of MFClientFS",
					   filesystemClass);
			}
		}
	}
	
	return fs;
}

- (id)initWithRemoteFS:(id)remoteFS 
		  clientPlugin:(MFClientPlugin*)p
{
	self = [super init];
	if (self != nil)
	{
		remoteFilesystem = remoteFS;
		plugin = p;
		[self fillInitialData];
		[self registerNotifications];
	}
	
	return self;
}


- (void)registerNotifications
{
	[self addObserver:self
		   forKeyPath:@"parameters"
			  options:NSKeyValueObservingOptionNew
			  context:nil];
}

- (void)fillInitialData
{
	[self willChangeValueForKey:@"parameters"];
	parameters = [[remoteFilesystem parameters] mutableCopy];
	[self didChangeValueForKey:@"parameters"];
	[self willChangeValueForKey:@"statusInfo"];
	statusInfo = [[remoteFilesystem statusInfo] mutableCopy];
	[self didChangeValueForKey:@"statusInfo"];
}

- (void)toggleMount:(id)sender
{
	[remoteFilesystem mount];
}

#pragma mark Synchronization across IPC
- (void)handleStatusInfoChangedNotification:(NSNotification*)note
{
//	NSDictionary* info = [note userInfo];
	[self willChangeValueForKey: @"status"];
	statusInfo = [[remoteFilesystem statusInfo] mutableCopy];
	[self didChangeValueForKey: @"status"];
}

- (void)handleParametersChangedNotification:(NSNotification*)note
{
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath 
					   ofObject:(id)object 
						 change:(NSDictionary *)change 
						context:(void *)context
{
	NSLog(@"Change detected on keypath %@, object %@, change %@",
		  keyPath, object, change);
}

// Hack to make sure we are notified if any parameters change
- (void)setValue:(id)value 
	  forKeyPath:(NSString*)keyPath
{
	if ([keyPath isLike:@"parameters.*"])
	{
		[self willChangeValueForKey:@"parameters"];
	}
	[super setValue:value
		 forKeyPath:keyPath];
	if ([keyPath isLike:@"parameters.*"])
	{
		[self didChangeValueForKey:@"parameters"];
		[remoteFilesystem setValue:value
						forKeyPath:keyPath];
	}
}

- (void)mount
{
	[remoteFilesystem mount];
}

- (void)unmount
{
	[remoteFilesystem unmount];
}

- (NSMutableDictionary*)parameters
{
	return parameters;
}

@end
