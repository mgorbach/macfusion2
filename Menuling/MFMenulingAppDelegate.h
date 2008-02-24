//
//  MFMenulingAppDelegate.h
//  MacFusion2
//
//  Created by Michael Gorbach on 2/23/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MFClient;

@interface MFMenulingAppDelegate : NSObject {
	NSStatusItem* statusItem;
	MFClient* client;
}

@end
