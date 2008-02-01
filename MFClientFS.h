//
//  MFClientFS.h
//  MacFusion2
//
//  Created by Michael Gorbach on 1/5/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFilesystem.h"

@class MFClientPlugin;

@interface MFClientFS : MFFilesystem {
	id remoteFilesystem;
	MFClientPlugin* plugin;
}

+ (MFClientFS*)clientFSWithRemoteFS:(id)remoteFS 
					   clientPlugin:(MFClientPlugin*)plugin;

- (id)initWithRemoteFS:(id)remoteFS 
		  clientPlugin:(MFClientPlugin*)p;

- (void)toggleMount:(id)sender;

// Notification handling
- (void)handleStatusInfoChangedNotification:(NSNotification*)note;
- (void)handleParametersChangedNotification:(NSNotification*)note;

@end
