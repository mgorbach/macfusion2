//
//  MFClientPlugin.h
//  MacFusion2
//
//  Created by Michael Gorbach on 1/12/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MFPlugin.h"

@interface MFClientPlugin : MFPlugin {
	id remotePlugin;
}

- (id)initWithRemotePlugin:(id)remotePlugin;

@end
