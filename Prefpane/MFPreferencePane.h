//
//  MFPreferencePane.h
//  MacFusion2
//
//  Created by Michael Gorbach on 12/8/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import "MFServerProtocol.h"

@interface MFPreferencePane : NSPreferencePane {
	IBOutlet id <MFServerProtocol> server;
	IBOutlet NSDictionaryController* filesystemDictionaryController;
	IBOutlet NSDictionaryController* pluginDictionaryController;
	IBOutlet NSObjectController* filesystemObjectController;
	IBOutlet NSView* configurationView;
	IBOutlet NSTabView* mainTabView;
	IBOutlet NSBox* confViewBox;
}

@end
