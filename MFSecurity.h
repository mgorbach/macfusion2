//
//  MFSecurity.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/10/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFilesystem.h"
#import <Security/Security.h>

#import "MFFilesystem.h"
#import "MFClientFS.h"

NSDictionary* getSecretsDictionaryForFilesystem( MFFilesystem* fs );

MFClientFS* getFilesystemForToken( NSString* token );

NSString* queryForFSNetworkPassword( MFClientFS* fs );

void setSecretsDictionaryForFilesystem( NSDictionary* secretsDictionary, MFFilesystem* fs );

NSString* tokenForFilesystemWithUUID (NSString* uuid );

NSString* uuidForKeychainItemRef(SecKeychainItemRef itemRef);