/*
 *  MFServerProtocol.h
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 12/7/07.
 *  Copyright 2007 Michael Gorbach. All rights reserved.
 *
 */
@class MFPluginController, MFFilesystemController, MFServerFS;

@protocol MFServerProtocol <NSObject>

- (NSArray*)filesystems;
- (NSArray*)plugins;

- (MFServerFS*)newFilesystemWithPluginName:(NSString*)pluginName;
- (MFServerFS*)filesystemWithUUID:(NSString*)uuid;
- (MFServerFS*)quickMountWithURL:(NSURL*)url;
- (NSError*)recentError;
- (NSArray*)recents;


@end


