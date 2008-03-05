//
//  MFMenulingAppDelegate.h
//  MacFusion2
//
//  Created by Michael Gorbach on 2/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFClientFSDelegateProtocol.h"

@class MFClient, MFQuickMountController;

@interface MFMenulingAppDelegate : NSObject <MFClientFSDelegateProtocol> {
	NSStatusItem* statusItem;
	MFClient* client;
	MFQuickMountController* qmController;
}

- (IBAction)connectToServer:(id)sender;

@end
