//
//  MFFilesystemController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 11/7/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MFServerFS, MFServerPlugin;

@interface MFFilesystemController : NSObject {
	NSMutableDictionary* filesystemsDictionary;
	NSMutableArray* filesystems;
	NSMutableArray* recents;
	NSMutableArray* mountedPaths;
	NSMutableDictionary* tokens;
	
	DASessionRef appearSession;
	DASessionRef disappearSession;
}

// Init
+ (MFFilesystemController*)sharedController;
- (void)loadFilesystems;


// Action methods
- (MFServerFS*)newFilesystemWithPlugin:(MFServerPlugin*)plugin;
- (MFServerFS*)quickMountWithURL:(NSURL*)url 
						   error:(NSError**)error;
- (void)deleteFilesystem:(MFServerFS*)fs;

- (MFServerFS*)filesystemWithUUID:(NSString*)uuid;

// Security Tokens
- (NSString*)tokenForFilesystem:(MFServerFS*)fs;
- (void)invalidateToken:(NSString*)token;
- (MFServerFS*)filesystemForToken:(NSString*)token;

// Accessors
- (NSDictionary*)filesystemsDictionary;
@property(readonly, retain) NSMutableArray* filesystems;
@property(readonly, retain) NSMutableArray* recents;
@end

