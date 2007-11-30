//
//  SSHFilesystem.m
//  MacFusion2
//
//  Created by Michael Gorbach on 11/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SSHFilesystem.h"


@implementation SSHFilesystem
- (NSArray*)taskArgumentList
{
	NSMutableArray* arguments;
	[arguments addObject: [NSString stringWithFormat:@"%@@%@:%@",
						   [parameters objectForKey:@"User"],
						   [parameters objectForKey:@"Host"],
						   [parameters objectForKey:@"Directory"]]];
	
	[arguments addObject: [parameters objectForKey: @"Mount Path"]];
	[arguments addObject: [parameters objectForKey: @"Port"]];
	
	[arguments addObject: @"-oCheckHostIP=no"];
	[arguments addObject: @"-oStrictHostKeyChecking=no"];
	[arguments addObject: @"-oNumberOfPasswordPrompts=1"];
	[arguments addObject: @"-ofollow_symlinks"];
	[arguments addObject: @"-f"];
}


@end
