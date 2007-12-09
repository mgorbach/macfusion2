//
//  SSHFilesystem.m
//  MacFusion2
//
//  Created by Michael Gorbach on 11/24/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SSHFilesystem.h"


@implementation SSHFilesystem
- (NSArray*)taskArguments
{
	NSMutableArray* arguments = [NSMutableArray array];
	[arguments addObject: [NSString stringWithFormat:@"%@@%@:%@",
						   [parameters objectForKey:@"User"],
						   [parameters objectForKey:@"Host"],
						   [parameters objectForKey:@"Directory"]]];
	
	[arguments addObject: [parameters objectForKey: @"Mount Point"]];
	[arguments addObject: [NSString stringWithFormat: @"-p%@", 
						   [parameters objectForKey: @"Port"]]];
	
	[arguments addObject: @"-oCheckHostIP=no"];
	[arguments addObject: @"-oStrictHostKeyChecking=no"];
	[arguments addObject: @"-oNumberOfPasswordPrompts=1"];
	[arguments addObject: @"-ofollow_symlinks"];
	[arguments addObject: [NSString stringWithFormat: @"-ovolname=", 
						   [parameters objectForKey:@"Volume Name"]]];
	[arguments addObject: @"-f"];
	return arguments;
}

- (NSMutableDictionary*)fullParametersWithDictionary:(NSDictionary*)fsParams
{
	// Epic scale hack enabled!
	NSMutableDictionary* hackedDictionary = [NSMutableDictionary dictionary];
	[hackedDictionary setObject:@"sccs" forKey:@"Host"];
	[hackedDictionary setObject:@"" forKey:@"Directory"];
	[hackedDictionary setObject:[NSNumber numberWithInt: 22]
						 forKey:@"Port"];
	[hackedDictionary setObject:@"mgorbach" forKey:@"User"];
	[hackedDictionary setObject:@"/Volumes/testMount" forKey:@"Mount Point"];
	[hackedDictionary setObject:@"Swarthmore"
						 forKey:@"Volume Name"];	
	return hackedDictionary;
}
@end
