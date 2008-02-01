//
//  MFFilesystem.h
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MFPlugin;

@interface MFFilesystem : NSObject {
	NSMutableDictionary* parameters;
	NSMutableDictionary* statusInfo;
}


// Key action methods
- (void)mount;
- (void)unmount;

// shortcut methods
- (BOOL)isMounted;
- (BOOL)isWaiting;
- (BOOL)isUnmounted;

@property(readwrite, assign) NSString* status;
@property(readonly, assign) NSString* uuid;
@property(readonly) NSString* mountPath;
@property(readonly) NSString* name;
@property(readonly) NSDictionary* parameters;
@property(readonly) NSDictionary* statusInfo;
@property(readonly) NSString* pluginID;
@property(readonly) NSString* descriptionString;

@end
