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

@interface MFServerFS : MFFilesystem {
	NSTask* task;
	MFServerPlugin* plugin;
}


// Server-specific initialization
+ (MFServerFS*)loadFilesystemAtPath:(NSString*)path 
							  error:(NSError**)error;

+ (MFServerFS*)newFilesystemWithPlugin:(MFServerPlugin*)plugin;


// Notification handling
- (void)handleMountNotification;
- (void)handleUnmountNotification;


// validate
- (BOOL)validateParametersWithError:(NSError**)error;

@property(retain) MFServerPlugin* plugin;
@end
