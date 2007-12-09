//
//  MFFilesystemController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 11/7/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFFilesystemController.h"
#import "MFPluginController.h"
#import "MFPlugin.h"
#import "MFFilesystem.h"

#define FSDEF_EXTENSION @"macfusion"


@implementation MFFilesystemController

static MFFilesystemController* sharedController = nil;


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

- (id) init
{
	self = [super init];
	if (self != nil) {
		filesystems = [[NSMutableArray alloc] init];
	}
	return self;
}


- (id)copyWithZone:(NSZone*)zone
{
	return self;
}

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

- (BOOL)validateFilesystemParameters:(NSDictionary*)params
{
	return YES;
}

- (void)loadFilesystems
{
	MFLog(@"Filesystems loading. Searching ...");
	NSArray* filesystemPaths = [self pathsToFilesystemDefs];
	for(NSString* fsPath in filesystemPaths)
	{
		MFLog(@"Loading fs at %@", fsPath);
		NSDictionary* fsParams = [NSDictionary dictionaryWithContentsOfFile:fsPath];
		if (fsParams && [self validateFilesystemParameters: fsParams])
		{
			NSString* type = [fsParams objectForKey:@"Type"];
			MFPlugin* plugin = [[MFPluginController sharedController] pluginWithID: type];
			if (plugin)
			{
				MFFilesystem* fs = [MFFilesystem filesystemFromParameters:fsParams 
																   plugin:plugin];
				[filesystems addObject: fs];
			}
			else
			{
				MFLog(@"Failed to find plugin for Filesystem");
			}
		}
	}
}

@synthesize filesystems;

@end 