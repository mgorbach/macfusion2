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
	id <MFFSDelegateProtocol> delegate;
}


// Server-specific initialization
+ (MFServerFS*)filesystemFromParameters:(NSDictionary*)parameters
								   plugin:(MFServerPlugin*)p;

- (MFServerFS*)initWithParameters:(NSDictionary*)params 
						   plugin:(MFServerPlugin*)p;



// Notification handling
- (void)handleMountNotification;
- (void)handleUnmountNotification;

@property(retain) MFServerPlugin* plugin;
@end
