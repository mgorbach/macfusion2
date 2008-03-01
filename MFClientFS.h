//
//  MFClientFS.h
//  MacFusion2
//
//  Created by Michael Gorbach on 1/5/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFilesystem.h"
#import "MFServerFSProtocol.h"

@class MFClientPlugin;

@interface MFClientFS : MFFilesystem {
	id<MFServerFSProtocol> remoteFilesystem;
	MFClientPlugin* plugin;
	NSDictionary* backupParameters;
	BOOL isEditing;
}

+ (MFClientFS*)clientFSWithRemoteFS:(id)remoteFS 
					   clientPlugin:(MFClientPlugin*)plugin;

- (id)initWithRemoteFS:(id)remoteFS 
		  clientPlugin:(MFClientPlugin*)p;

// Notification handling
- (void)handleStatusInfoChangedNotification:(NSNotification*)note;
- (void)handleParametersChangedNotification:(NSNotification*)note;

// Editing
- (NSError*)endEditingAndCommitChanges:(BOOL)commit;
- (void)beginEditing;
- (NSDictionary*)displayDictionary;

@end
