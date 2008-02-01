//
//  SSHFilesystem.m
//  MacFusion2
//
//  Created by Michael Gorbach on 11/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SSHServerFS.h"


@implementation SSHServerFS

- (void)postProcessParameters
{
	if (![parameters objectForKey: @"Mount Path"])
	{
		NSString* mountPath = [NSString stringWithFormat: 
							   @"/Volumes/%@", 
							   [parameters objectForKey:@"Host"]];
		[parameters setObject: mountPath
					   forKey: @"Mount Path"];
	}
	if (![parameters objectForKey: @"Volume Name"])
	{
		if ([parameters objectForKey: @"Host"])
		{
			[parameters setObject: [parameters objectForKey: @"Host"]
					   forKey: @"Volume Name"];
		}
	}
}

- (NSArray*)taskArguments
{
	NSDictionary* params = [self parameters];
	NSMutableArray* arguments = [NSMutableArray array];
	[arguments addObject: [NSString stringWithFormat:@"%@@%@:%@",
						   [params objectForKey:@"User"],
						   [parameters objectForKey:@"Host"],
						   [parameters objectForKey:@"Directory"]]];
	
	[arguments addObject: [parameters objectForKey: @"Mount Path"]];
	[arguments addObject: [NSString stringWithFormat: @"-p%@", 
						   [parameters objectForKey: @"Port"]]];
	
	[arguments addObject: @"-oCheckHostIP=no"];
	[arguments addObject: @"-oStrictHostKeyChecking=no"];
	[arguments addObject: @"-oNumberOfPasswordPrompts=1"];
	[arguments addObject: @"-ofollow_symlinks"];
	[arguments addObject: [NSString stringWithFormat: @"-ovolname=%@", 
						   [parameters objectForKey:@"Volume Name"]]];
	[arguments addObject: @"-f"];
	return arguments;
}

@end
