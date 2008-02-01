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
- (void)fire
{
	NSLog(@"Tick");
}

- (void)startRunloop
{
	NSRunLoop* runloop = [NSRunLoop currentRunLoop];
	MFLog(@"Runloop initialized! Let's roll!");
	[runloop run];
}

- (void)runTests:(id)timer
{
//	MFFilesystem* fs = [[[MFFilesystemController sharedController] filesystems]
//						objectAtIndex:0];
//	MFLogS(self,@"TICK %@", [MFFilesystemController sharedController].filesystems);
//	[fs mount];
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
