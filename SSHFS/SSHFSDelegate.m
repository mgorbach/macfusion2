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

#pragma mark Plugin Info
- (NSString*)executablePath
{
	return [[NSBundle bundleForClass: [self class]]
			pathForResource:@"sshfs-static"
			ofType:nil
			inDirectory:nil];
}

#pragma mark Mounting
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
	[arguments addObject: @"-ologlevel=debug"];
	[arguments addObject: @"-f"];
	return [arguments copy];
}

# pragma mark Quickmount
- (NSArray*)urlSchemesHandled
{
	return [NSArray arrayWithObjects: @"ssh", @"sftp", nil];
}

- (NSDictionary*)parameterDictionaryForURL:(NSURL*)url
									 error:(NSError**)error
{
	NSString* host = [url host];
	NSString* userName = [url user];
	NSNumber* port = [url port];
	NSString* directory = [url relativePath];
	
	NSMutableDictionary* params = [[self defaultParameterDictionary] mutableCopy];
	if (host)
		[params setObject:host forKey:kSSHFSHostParameter];
	if (userName)
		[params setObject:userName forKey:kSSHFSUserParameter];
	if (port)
		[params setObject:port forKey:kSSHFSPortParameter];
	if (directory)
		[params setObject:directory forKey:kSSHFSDirectoryParameter];
	
	return [params copy];
}

# pragma mark Parameters
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
	if ( ![parameters objectForKey: kSSHFSHostParameter] )
	{
		description = @"No host specified";
	}
	else
	{
		if( [parameters objectForKey: kSSHFSUserParameter] && 
			![[parameters objectForKey: kSSHFSUserParameter] isEqualTo: NSUserName()])
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
	if ([parameterName isEqualToString: kMFFSNameParameter])
		return [parameters objectForKey: kSSHFSHostParameter];
	
	return nil;
}

# pragma mark Validation
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
	
	if (![parameters objectForKey: kSSHFSHostParameter])
	{
		*error = [MFError parameterMissingErrorWithParameterName: kSSHFSHostParameter ];
		return NO;
	}
	
	return YES;
}

- (NSError*)errorForParameters:(NSDictionary*)parameters 
						output:(NSString*)output
{
	if ([output rangeOfString: @"Permission denied"].location != NSNotFound)
	{
		return [MFError errorWithErrorCode:kMFErrorCodeMountFaliure
							   description:@"Authentication has failed."];
	}
	
	if ([output rangeOfString: @"remote host has disconnected"].location != NSNotFound)
	{
		return [MFError errorWithErrorCode:kMFErrorCodeMountFaliure
							   description:@"Remote host has disconnected."];
	}
	

	return nil;
}

@end
