//
//  MFClientPlugin.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/12/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFClientPlugin.h"
#import "MFPlugin.h"

@interface MFClientPlugin (PrivateAPI)
- (void)fillInitialData;
@end

@implementation MFClientPlugin
- (id)initWithRemotePlugin:(id)remote
{
	self = [super init];
	if (self != nil)
	{
		remotePlugin = remote;
		[self fillInitialData];
		delegate = [self setupDelegate];
		if(!delegate)
		{
			return nil;
		}
	}
	
	return self;
}

- (void)fillInitialData
{
	dictionary = [remotePlugin dictionary];
	bundle = [NSBundle bundleWithPath: [remotePlugin bundlePath]];
}


@end
