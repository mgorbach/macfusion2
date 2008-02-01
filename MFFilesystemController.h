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
	DASessionRef appearSession;
	DASessionRef disappearSession;
}

+ (MFFilesystemController*)sharedController;
- (void)loadFilesystems;
- (NSDictionary*)filesystemsDictionary;
- (NSArray*)filesystems;
- (MFServerFS*)newFilesystemWithPlugin:(MFServerPlugin*)plugin;
- (MFServerFS*)filesystemWithUUID:(NSString*)uuid;

@end

