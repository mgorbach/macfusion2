//
//  MFCommunicationServer.h
//  MacFusion2
//
//  Created by Michael Gorbach on 12/7/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFServerProtocol.h"

@class MFFilesystemController, MFPluginController;

@interface MFCommunicationServer : NSObject <MFServerProtocol>
{
	NSError* recentError;
}

+ (MFCommunicationServer*)sharedServer;

- (MFFilesystemController*)filesystemController;
- (MFPluginController*)pluginController;
- (void)startServingRunloop;
- (NSError*)recentError;

@end
