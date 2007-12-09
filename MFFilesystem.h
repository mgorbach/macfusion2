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
	MFPlugin* plugin;
	NSTask* task;
	NSString* status;
	NSString* faliureReason;
	NSString* recentOutput;
}

+ (MFFilesystem*)filesystemFromParameters:(NSDictionary*)parameters
								   plugin:(MFPlugin*)p;

- (MFFilesystem*)initWithParameters:(NSDictionary*)parameters 
							 plugin:(MFPlugin*)p;
- (NSDictionary*)parameterDictionary;

- (NSMutableDictionary*)fullParametersWithDictionary: (NSDictionary*)fsParams;
- (NSArray*)taskArguments;

- (BOOL)validateValue:(id)value forParameterNamed:(NSString*)param;

- (NSString*)pluginID;

- (void)mount;

// - (void)unmount;

@property(readonly) MFPlugin* plugin;
@property(retain) NSString* status;

@end
