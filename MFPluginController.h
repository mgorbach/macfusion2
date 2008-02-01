//
//  MFPluginController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 11/6/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MFServerFS, MFServerPlugin;

@interface MFPluginController : NSObject {
	NSMutableDictionary* pluginsDictionary;
}

+ (MFPluginController*)sharedController;

- (MFServerPlugin*)pluginWithID:(NSString*)ID;
- (void)loadPlugins;
- (NSArray*)plugins;
- (NSDictionary*)pluginsDictionary;

@end
