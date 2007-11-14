//
//  MacFusionController.h
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define TEMP_SSHFS_PATH @"/Users/mgorbach/Library/Macfusion/Plugins/SSHFS.bundle"

@interface MFMainController : NSObject {
	
}

+ (MFMainController*)sharedController;
- (void)initialize;

// - (void)loadPlugins;
@end
