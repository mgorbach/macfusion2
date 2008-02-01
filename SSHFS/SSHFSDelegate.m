//
//  SSHFSDelegate.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/31/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "SSHFSDelegate.h"


@implementation SSHFSDelegate
- (NSArray*)taskArgumentsForParameters:(NSDictionary*)parameters
{
	NSMutableArray* arguments = [NSMutableArray array];
	[arguments addObject: [NSString stringWithFormat:@"%@@%@:%@",
						   [parameters objectForKey:@"User"],
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
	return [arguments copy];
}

- (NSString*)executablePath
{
	return @"/usr/local/bin/sshfs";
}

- (NSDictionary*)defaultParameterDictionary
{
	NSDictionary* defaultParameters = [NSDictionary dictionaryWithObjectsAndKeys: 
						 [NSNull null], @"name",
						 NSUserName(), @"User",
						 [NSNull null], @"Host",
						 @"", @"Directory",
						 [NSNull null], @"Mount Path",
						 [NSNumber numberWithInt: 22], @"Port",
								nil];
	
	return defaultParameters;
}

- (NSString*)descriptionForParameters:(NSDictionary*)parameters
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

- (id)impliedValueParameterNamed:(NSString*)name 
				 otherParameters:(NSDictionary*)parameters;
{
	if ([name isEqualToString: @"Mount Path"] && 
		[parameters objectForKey: @"Host"] != [NSNull null])
	{
		NSString* mountPath = [NSString stringWithFormat: 
							   @"/Volumes/%@", 
							   [parameters objectForKey:@"Host"]];
		return mountPath;
	}
	if ([name isEqualToString: @"Volume Name"] &&
		[parameters objectForKey: @"Host"] != [NSNull null])
	{
		return [parameters objectForKey:@"Host"];
	}
	
	return nil;
}

- (BOOL)validateValue:(id)value 
	 forParameterName:(NSString*)paramName 
				error:(NSError**)error
{
	if ([paramName isEqualToString: @"Port"])
	{
		if( [value isKindOfClass: [NSNumber class]] && 
			[(NSNumber*)value intValue] > 1 &&
			[(NSNumber*)value intValue] < 10000 )
		{
			return YES;
		}
		else
		{
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)validateParameters:(NSDictionary*)parameters
					 error:(NSError**)error
{
	return YES;
}

@end
