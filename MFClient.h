//
//  MFClient.h
//  MacFusion2
//
//  Created by Michael Gorbach on 12/10/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFServerProtocol.h"

@class MFClientFS, MFClientPlugin;

@interface MFClient : NSObject {
	NSMutableDictionary* filesystemsDictionary;
	NSMutableArray* filesystems;
	NSMutableDictionary* pluginsDictionary;
	NSMutableArray* plugins;
	id <MFServerProtocol> server;
	id delegate;
}

+ (MFClient*)sharedClient;
- (BOOL)setup;

- (NSArray*)filesystems;
- (NSArray*)plugins;

// Action methods
- (MFClientFS*)newFilesystemWithPlugin:(MFClientPlugin*)plugin;

// Accessors
- (MFClientFS*)filesystemWithUUID:(NSString*)uuid;
- (MFClientPlugin*)pluginWithID:(NSString*)id;

@property(retain) id delegate;

@end
