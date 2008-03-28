/*
 *  MFClientProtocol.h
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 3/25/08.
 *  Copyright 2008 Michael Gorbach. All rights reserved.
 *
 */

@protocol MFClientProtocol <NSObject>
// Updates
- (void)noteStatusChangedForFSWithUUID:(NSString*)uuid;

// Filesystems Array
- (void)noteFilesystemAddedWithUUID:(NSString*)uuid;
- (void)noteFilesystemRemovedWithUUID:(NSString*)uuid;

// Recents
- (void)noteRecentAdded:(NSDictionary*)recentParameters;

// Logging
- (void)recordASLMessageDict:(NSDictionary*)messageDict;
@end