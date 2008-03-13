//
//  MFServerFS.h
//  MacFusion2
//
//  Created by Michael Gorbach on 1/12/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFilesystem.h"
#import "MFServerPlugin.h"
#import "MFFSDelegateProtocol.h"
#import "MFServerFSProtocol.h"

@interface MFServerFS : MFFilesystem <MFServerFSProtocol> {
	NSTask* task;
	MFServerPlugin* plugin;
	BOOL pauseTimeout;
	NSTimer* timer;
}


// Server-specific initialization
+ (MFServerFS*)loadFilesystemAtPath:(NSString*)path 
							  error:(NSError**)error;

+ (MFServerFS*)newFilesystemWithPlugin:(MFServerPlugin*)plugin;

+ (MFServerFS*)filesystemFromURL:(NSURL*)url
						  plugin:(MFServerPlugin*)p
						   error:(NSError**)error;


// Notification handling
- (void)handleMountNotification;
- (void)handleUnmountNotification;

- (void)removeMountPoint;

// validate
- (BOOL)validateParametersWithError:(NSError**)error;

@property(retain) MFServerPlugin* plugin;
@property(assign, readwrite) BOOL pauseTimeout;
@end
