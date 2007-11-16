//
//  MFPlugin.h
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MFPlugin : NSObject {
	NSMutableDictionary* dictionary;
	NSBundle* bundle;
}

@property(readonly) NSMutableDictionary* dictionary;
@property(readonly) NSString* id;
@property(readonly) NSString* inputFormatString;

+ (MFPlugin*)pluginFromBundleAtPath:(NSString*)path;

- (NSDictionary*)defaultParameterDictionary;

@end
