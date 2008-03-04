//
//  MacFusionController.m
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFMainController.h"
#import "MFPlugin.h"
#import "MFPluginController.h"
#import "MFFilesystemController.h"
#import "MFFilesystem.h"
#import "MFCommunicationServer.h"
#include <sys/xattr.h>

@implementation MFMainController
static MFMainController* sharedController = nil;

#pragma mark Singleton Methods
+ (MFMainController*)sharedController
{
	if (sharedController == nil)
	{
		[[self alloc] init];
	}
	
	return sharedController;
}

+ (id)allocWithZone:(NSZone*) zone
{
	if (sharedController == nil)
	{
		sharedController = [super allocWithZone:zone];
		return sharedController;
	}
	
	return nil;
}

- (id)copyWithZone:(NSZone*)zone
{
	return self;
}

#pragma mark Runloop and initialization methods

- (void)startRunloop
{
	NSRunLoop* runloop = [NSRunLoop currentRunLoop];

	[runloop run];
}

- (void)initialize
{
	MFPluginController* pluginController = [MFPluginController sharedController];
	MFFilesystemController* filesystemController = [MFFilesystemController sharedController];
	[pluginController loadPlugins];
	[filesystemController loadFilesystems];
	
	[[MFCommunicationServer sharedServer] startServingRunloop];
}

@end
