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
#import "MFClientFSDelegateProtocol.h"

@class MFClientPlugin;

@interface MFClientFS : MFFilesystem {
	id<MFServerFSProtocol> remoteFilesystem;
	MFClientPlugin* plugin;
	NSDictionary* backupParameters;
	NSDictionary* backupSecrets;
	BOOL isEditing;
	NSInteger displayOrder;
	id<MFClientFSDelegateProtocol> clientFSDelegate;
}

+ (MFClientFS*)clientFSWithRemoteFS:(id)remoteFS 
					   clientPlugin:(MFClientPlugin*)plugin;

- (id)initWithRemoteFS:(id)remoteFS 
		  clientPlugin:(MFClientPlugin*)p;

// Notification handling
- (void)handleStatusInfoChangedNotification:(NSNotification*)note;
- (void)handleParametersChangedNotification:(NSNotification*)note;
- (void)setPauseTimeout:(BOOL)p;

// Editing
- (NSError*)endEditingAndCommitChanges:(BOOL)commit;
- (void)beginEditing;
- (NSDictionary*)displayDictionary;

// UI
- (NSDictionary*)configurationViewControllers;

@property(readwrite, assign) NSInteger displayOrder;
@property(readwrite, retain) id<MFClientFSDelegateProtocol> clientFSDelegate; 
@property(readonly) NSImage* iconImage;
@end
