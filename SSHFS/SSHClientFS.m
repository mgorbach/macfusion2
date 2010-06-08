//
//  SSHClientFS.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/30/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "SSHClientFS.h"


@implementation SSHClientFS
- (NSString*)descriptionString
{
	NSString* description = nil;
	if (![parameters objectForKey:@"Host"])
	{
		description = @"No host specified";
	}
	else
	{
		if([parameters objectForKey:@"User"])
		{
			description = [NSString stringWithFormat:@"%@@%@",
						   [parameters objectForKey:@"User"],
						   [parameters objectForKey:@"Host"]];
		}
		else
		{
			description = [NSString stringWithString: 
						   [parameters objectForKey:@"Host"]];
		}
	}
	
	return description;
}
@end
