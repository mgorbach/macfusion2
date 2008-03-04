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
	
	DASessionRef appearSession;
	DASessionRef disappearSession;
	
	BOOL firstTimeMounting;
}

+ (MFFilesystemController*)sharedController;
- (void)loadFilesystems;
- (NSDictionary*)filesystemsDictionary;
- (NSMutableArray*)filesystems;
- (MFServerFS*)newFilesystemWithPlugin:(MFServerPlugin*)plugin;
- (MFServerFS*)quickMountWithURL:(NSURL*)url 
						   error:(NSError**)error;

- (void)storeFilesystem:(MFServerFS*)fs;
- (MFServerFS*)filesystemWithUUID:(NSString*)uuid;

- (void)addMountedPath:(NSString*)path;
- (void)removeMountedPath:(NSString*)path;


@property(readonly, retain) NSMutableArray* filesystems;
@property(readonly, retain) NSMutableArray* recents;
@end

