//
//  MFCore.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/11/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFilesystem.h"

// Locations of clients
NSString* mainUIBundlePath();
NSString* menulingUIBundlePath();
NSArray* secretClientsForFileystem( MFFilesystem* fs );

// Launch Services and Login Items Control
BOOL getStateForAgentLoginItem();
BOOL setStateForAgentLoginItem(BOOL state);
BOOL getStateForMenulingLoginItem();
BOOL setStateForMenulingLoginItem(BOOL state);


// FUSE versioning
NSString* getMacFuseVersion();