//
//  MFFilesystem.h
//  MacFusion2
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFFSDelegateProtocol.h"

@class MFPlugin;

@interface MFFilesystem : NSObject {
	NSMutableDictionary* parameters;
	NSMutableDictionary* statusInfo;
	id <MFFSDelegateProtocol> delegate;
	NSMutableDictionary* secrets;
}


// Key action methods
- (void)mount;
- (void)unmount;

// shortcut methods
- (BOOL)isMounted;
- (BOOL)isWaiting;
- (BOOL)isUnmounted;
- (BOOL)isFailedToMount;
- (BOOL)isPersistent;

- (NSMutableDictionary*)parametersWithImpliedValues;
- (NSArray*)parameterList;
- (id)valueForParameterNamed:(NSString*)paramName;
- (NSMutableDictionary*)fillParametersWithImpliedValues:(NSDictionary*)params;
- (NSError*)error;
- (id <MFFSDelegateProtocol>)delegate;
- (void)updateSecrets;

@property(readwrite, assign) NSString* status;
@property(readonly, assign) NSString* uuid;
@property(readonly) NSString* mountPath;
@property(readonly) NSString* name;
@property(readonly) NSMutableDictionary* parameters;
@property(readonly) NSDictionary* statusInfo;
@property (readwrite, retain) NSMutableDictionary* secrets;
@property(readonly) NSString* pluginID;
@property(readonly) NSString* descriptionString;
@property(readonly) NSString* iconPath;
@property(readonly) NSString* filePath;
@property(readonly) NSString* imagePath;

@end
