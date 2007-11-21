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
}

+ (MFFilesystem*)filesystemFromParameters:(NSDictionary*)parameters
								   plugin:(MFPlugin*)p;

- (MFPlugin*)plugin;
- (MFFilesystem*)initWithParameters:(NSDictionary*)parameters 
							 plugin:(MFPlugin*)p;
- (NSDictionary*)parameterDictionary;
- (NSString*)pluginID;
//- (void)mount;
//- (void)unmount;


@end
