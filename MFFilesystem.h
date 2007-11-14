//
//  MFFilesystem.h
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MFFilesystem : NSObject {
	NSMutableDictionary* parameters;
}

+ (MFFilesystem*)filesystemFromParameters:(NSDictionary*)parameters;

- (MFPlugin*)plugin;
- (MFFilesystem*)initWithParameters:(NSDictionary*)parameters;
- (NSDictionary*)parameterDictionary;
//- (void)mount;
//- (void)unmount;


@end
