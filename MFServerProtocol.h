/*
 *  MFServerProtocol.h
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 12/7/07.
 *  Copyright 2007 Michael Gorbach. All rights reserved.
 *
 */
@class MFPluginController, MFFilesystemController;

@protocol MFServerProtocol <NSObject>

- (MFPluginController*)pluginController;
- (MFFilesystemController*)filesystemController;
- (void)sendStatus;

@end


