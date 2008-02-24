//
//  SSHFSDelegate.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/31/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "SSHFSDelegate.h"
#import "MFConstants.h"
#import "MGUtilities.h"
#import "MFError.h"

// SSHFS Parameter Names
#define kSSHFSHostParameter @"Host"
#define kSSHFSPortParameter @"Port"
#define kSSHFSDirectoryParameter @"Directory"
#define kSSHFSUserParameter @"User"

@implementation SSHFSDelegate
- (NSArray*)taskArgumentsForParameters:(NSDictionary*)parameters
{
	NSMutableArray* arguments = [NSMutableArray array];
	[arguments addObject: [NSString stringWithFormat:@"%@@%@:%@",
						   [parameters objectForKey: kSSHFSUserParameter],
						   [parameters objectForKey: kSSHFSHostParameter],
						   [parameters objectForKey: kSSHFSDirectoryParameter]]];
	
	[arguments addObject: [parameters objectForKey: kMFFSMountPathParameter ]];
	[arguments addObject: [NSString stringWithFormat: @"-p%@", 
						   [parameters objectForKey: kSSHFSPortParameter ]]];
	
	[arguments addObject: @"-oCheckHostIP=no"];
	[arguments addObject: @"-oStrictHostKeyChecking=no"];
	[arguments addObject: @"-oNumberOfPasswordPrompts=1"];
	[arguments addObject: @"-ofollow_symlinks"];
	
	[arguments addObject: [NSString stringWithFormat: @"-ovolname=%@", 
						   [parameters objectForKey: kMFFSVolumeNameParameter]]];
	[arguments addObject: @"-f"];
	return [arguments copy];
}

- (NSString*)executablePath
{
	return @"/usr/local/bin/sshfs";
}

- (NSArray*)parameterList
{
	return [NSArray arrayWithObjects: kSSHFSUserParameter, 
			kSSHFSHostParameter, kSSHFSDirectoryParameter, kSSHFSUserParameter,
			kSSHFSPortParameter, nil ];
}

- (NSDictionary*)defaultParameterDictionary
{
	NSDictionary* defaultParameters = [NSDictionary dictionaryWithObjectsAndKeys: 
						 NSUserName(), kSSHFSUserParameter,
						 @"", kSSHFSDirectoryParameter,
						 [NSNumber numberWithInt: 22], kSSHFSPortParameter,
								nil];
	
	return defaultParameters;
}

- (NSString*)descriptionForParameters:(NSDictionary*)parameters
{
	NSString* description = nil;
	if ( isNilOrNull( [parameters objectForKey: kSSHFSHostParameter] ) )
	{
		description = @"No host specified";
	}
	else
	{
		if( isNotNilOrNull( [parameters objectForKey: kSSHFSUserParameter] ) )
		{
			description = [NSString stringWithFormat:@"%@@%@",
						   [parameters objectForKey: kSSHFSUserParameter],
						   [parameters objectForKey: kSSHFSHostParameter]];
		}
		else
		{
			description = [NSString stringWithString: 
						   [parameters objectForKey: kSSHFSHostParameter]];
		}
	}
	
	return description;
}

- (id)impliedValueParameterNamed:(NSString*)parameterName 
				 otherParameters:(NSDictionary*)parameters;
{
	if ([parameterName isEqualToString: kMFFSMountPathParameter] && 
		[parameters objectForKey: kSSHFSHostParameter] )
	{
		NSString* mountPath = [NSString stringWithFormat: 
							   @"/Volumes/%@", 
							   [parameters objectForKey: kSSHFSHostParameter]];
		return mountPath;
	}
	if ([parameterName isEqualToString: kMFFSVolumeNameParameter] &&
		[parameters objectForKey: kSSHFSHostParameter] )
	{
		return [parameters objectForKey: kSSHFSHostParameter];
	}
	
	if ([parameterName isEqualToString: kMFFSVolumeIconPathParameter])
	{
		return [[NSBundle bundleForClass: [self class]] 
				pathForImageResource:@"sshfs"];
	}
	
	return nil;
}

- (BOOL)validateValue:(id)value 
	 forParameterName:(NSString*)paramName 
				error:(NSError**)error
{
	if ([paramName isEqualToString: kSSHFSPortParameter ])
	{
		if( [value isKindOfClass: [NSNumber class]] && 
			[(NSNumber*)value intValue] > 1 &&
			[(NSNumber*)value intValue] < 10000 )
		{
			return YES;
		}
		else
		{
			*error = [MFError invalidParameterValueErrorWithParameterName: kSSHFSPortParameter
																	value: value
															  description: @"Must be positive number < 10000"];
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)validateParameters:(NSDictionary*)parameters
					 error:(NSError**)error
{
	for (NSString* paramName in [parameters allKeys])
	{
		BOOL ok = [self validateValue: [parameters objectForKey: paramName]
					 forParameterName: paramName
								error: error];
		
		if (!ok)
		{
			return NO;
		}
	}
	
	if (![parameters objectForKey: kSSHFSHostParameter ])
	{
		*error = [MFError parameterMissingErrorWithParameterName: kSSHFSHostParameter ];
		return NO;
	}
	return YES;
}

@end
