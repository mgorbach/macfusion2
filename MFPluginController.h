//
//  MFPluginController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 11/6/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MFPluginController : NSObject {
	NSMutableDictionary* plugins;
}

+ (MFPluginController*)sharedController;

- (MFPlugin*)pluginWithID:(NSString*)ID;
- (void)loadPlugins;
- (NSMutableArray*) plugins;

@end
