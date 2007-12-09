//
//  MFCommunicationServer.m
//  MacFusion2
//
//  Created by Michael Gorbach on 12/7/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFCommunicationServer.h"
#import "MFFilesystemController.h"
#import "MFPluginController.h"

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
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		[self registerNotifications];
	}
	return self;
}

- (void)vendDisributedObject
{
	NSConnection* connection = [NSConnection defaultConnection];
	// TODO: Vend a proxy to set up protocol instead of, um , everything
	[connection setRootObject:self];
	if ([connection registerName:@"macfusion"] == YES)
	{
		MFLogS(self, @"Now Vending distributed object");
	}
	else
	{
		MFLogS(self, @"Failed to register connection name");
	}
}

- (void) observeValueForKeyPath:(NSString *)keyPath 
					   ofObject:(id)object
						 change:(NSDictionary *)change
						context:(void *)context
{
//	MFLogS(self, @"Observe triggered on keypath %@, object %@", keyPath, object);
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
	[self vendDisributedObject];
	[[NSRunLoop currentRunLoop] run];
}

- (void)sendStatus
{
	MFLogS(self, @"Status send triggered");
}

@end
