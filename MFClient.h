//
//  MFClient.h
//  MacFusion2
//
//  Created by Michael Gorbach on 12/10/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFServerProtocol.h"

@class MFClientFS, MFClientPlugin, MFClientRecent;

@interface MFClient : NSObject {
	NSMutableDictionary* filesystemsDictionary;
	NSMutableArray* filesystems;
	NSMutableDictionary* pluginsDictionary;
	NSMutableArray* plugins;
	NSMutableArray* recents;
	id <MFServerProtocol> server;
	id delegate;
}

+ (MFClient*)sharedClient;
- (BOOL)setup;

// Action methods
- (MFClientFS*)newFilesystemWithPlugin:(MFClientPlugin*)plugin;
- (MFClientFS*)quickMountFilesystemWithURL:(NSURL*)url
									 error:(NSError**)error;
- (MFClientFS*)mountRecent:(MFClientRecent*)recent
					 error:(NSError**)error;

// Accessors
- (MFClientFS*)filesystemWithUUID:(NSString*)uuid;
- (MFClientPlugin*)pluginWithID:(NSString*)id;

@property(retain) id delegate;

// All filesystems, including temporary ones
@property(readonly) NSArray* filesystems;

// Only filesystems that are not temporary
@property(readonly) NSArray* persistentFilesystems;
@property(readonly) NSArray* mountedFilesystems;

// All plugins
@property (readonly) NSArray* plugins;
@property(readonly) NSArray* recents;

@end
