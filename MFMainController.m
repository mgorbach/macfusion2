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
	NSLog(@"Runloop initialized! Let's roll!");
	[runloop run];
}

- (void)setupCommunication
{
	NSConnection* connection = [NSConnection defaultConnection];
	// TODO: Vend a proxy to set up protocol instead of, um , everything
	[connection setRootObject:self];
	if ([connection registerName:@"macfusion"] == YES)
	{
		NSLog(@"Now Vending distributed object");
	}
	else
	{
		NSLog(@"Failed to register connection name");
	}
}

- (void)initialize
{
	MFPluginController* pluginController = [MFPluginController sharedController];
	MFFilesystemController* filesystemController = [MFFilesystemController sharedController];
	[pluginController loadPlugins];
	[filesystemController loadFilesystems];
	[self setupCommunication];
	[self startRunloop];
}

@end
