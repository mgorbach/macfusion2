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
#import "MFNetworkFS.h"
#import "MFSecurity.h"
#import <Security/Security.h>

// SSHFS Parameter Names


@implementation SSHFSDelegate

#pragma mark Plugin Info
- (NSString*)askpassPath
{
	return [[NSBundle bundleForClass: [self class]]
			pathForResource:@"new_sshfs_askpass"
			ofType:nil
			inDirectory:nil];
}

- (NSString*)executablePath
{
	return [[NSBundle bundleForClass: [self class]]
			pathForResource:@"sshfs-static"
			ofType:nil
			inDirectory:nil];
}

- (NSArray*)secretsClientsList;
{
	return [NSArray arrayWithObjects: [self askpassPath], nil];
}

#pragma mark Mounting
- (NSArray*)taskArgumentsForParameters:(NSDictionary*)parameters
{
	NSMutableArray* arguments = [NSMutableArray array];
	[arguments addObject: [NSString stringWithFormat:@"%@@%@:%@",
						   [parameters objectForKey: kNetFSUserParameter],
						   [parameters objectForKey: kNetFSHostParameter],
						   [parameters objectForKey: kNetFSDirectoryParameter]]];
	
	[arguments addObject: [parameters objectForKey: kMFFSMountPathParameter ]];
	[arguments addObject: [NSString stringWithFormat: @"-p%@", 
						   [parameters objectForKey: kNetFSPortParameter ]]];
	
	[arguments addObject: @"-oCheckHostIP=no"];
	[arguments addObject: @"-oStrictHostKeyChecking=no"];
	[arguments addObject: @"-oNumberOfPasswordPrompts=1"];
	[arguments addObject: @"-ofollow_symlinks"];
	[arguments addObject: [NSString stringWithFormat: @"-ovolname=%@", 
						   [parameters objectForKey: kMFFSVolumeNameParameter]]];
	[arguments addObject: @"-ologlevel=debug"];
	[arguments addObject: @"-f"];
	[arguments addObject: [NSString stringWithFormat: @"-ovolicon=%@", 
						   [parameters objectForKey: kMFFSVolumeIconPathParameter]]];
	// MFLogS(self, @"Arguments are %@", arguments);
	return [arguments copy];
}

- (NSDictionary*)taskEnvironmentForParameters:(NSDictionary*)params
{
	NSMutableDictionary* env = [NSMutableDictionary dictionaryWithDictionary: 
								[[NSProcessInfo processInfo] environment]];
	[env setObject: [self askpassPath] forKey:@"SSH_ASKPASS"];
	[env setObject: tokenForFilesystemWithUUID([params objectForKey: KMFFSUUIDParameter])
			forKey: @"SSHFS_TOKEN"];

	// MFLogS(self, @"Returning environment %@", env);
	return [env copy];
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
		[params setObject:host forKey:kNetFSHostParameter];
	if (userName)
		[params setObject:userName forKey:kNetFSUserParameter];
	if (port)
		[params setObject:port forKey:kNetFSPortParameter];
	if (directory)
		[params setObject:directory forKey:kNetFSDirectoryParameter];
	
	return [params copy];
}

# pragma mark Parameters
- (NSArray*)parameterList
{
	return [NSArray arrayWithObjects: kNetFSUserParameter, 
			kNetFSHostParameter, kNetFSDirectoryParameter, kNetFSUserParameter,
			kNetFSPortParameter, kNetFSProtocolParameter, nil ];
}

- (NSArray*)secretsList
{
	return [NSArray arrayWithObjects: kNetFSPasswordParameter, nil];
}

- (NSDictionary*)defaultParameterDictionary
{
	NSDictionary* defaultParameters = [NSDictionary dictionaryWithObjectsAndKeys: 
						 NSUserName(), kNetFSUserParameter,
						 @"", kNetFSDirectoryParameter,
						 [NSNumber numberWithInt: 22], kNetFSPortParameter,
						[NSNumber numberWithInt: kSecProtocolTypeSSH], kNetFSProtocolParameter,
								nil];
	
	return defaultParameters;
}

- (NSString*)descriptionForParameters:(NSDictionary*)parameters
{
	NSString* description = nil;
	if ( ![parameters objectForKey: kNetFSHostParameter] )
	{
		description = @"No host specified";
	}
	else
	{
		if( [parameters objectForKey: kNetFSUserParameter] && 
			![[parameters objectForKey: kNetFSUserParameter] isEqualTo: NSUserName()])
		{
			description = [NSString stringWithFormat:@"%@@%@",
						   [parameters objectForKey: kNetFSUserParameter],
						   [parameters objectForKey: kNetFSHostParameter]];
		}
		else
		{
			description = [NSString stringWithString: 
						   [parameters objectForKey: kNetFSHostParameter]];
		}
	}
	
	return description;
}

- (id)impliedValueParameterNamed:(NSString*)parameterName 
				 otherParameters:(NSDictionary*)parameters;
{
	if ([parameterName isEqualToString: kMFFSMountPathParameter] && 
		[parameters objectForKey: kNetFSHostParameter] )
	{
		NSString* mountPath = [NSString stringWithFormat: 
							   @"/Volumes/%@", 
							   [parameters objectForKey: kNetFSHostParameter]];
		return mountPath;
	}
	if ([parameterName isEqualToString: kMFFSVolumeNameParameter] &&
		[parameters objectForKey: kNetFSHostParameter] )
	{
		return [parameters objectForKey: kNetFSHostParameter];
	}
	
	if ([parameterName isEqualToString: kMFFSVolumeIconPathParameter])
	{
		return [[NSBundle bundleForClass: [self class]] 
				pathForImageResource:@"sshfs_icon"];
	}
	if ([parameterName isEqualToString: kMFFSVolumeImagePathParameter])
	{
		return [[NSBundle bundleForClass: [self class]]
				pathForImageResource: @"sshfs"];
	}
	if ([parameterName isEqualToString: kMFFSNameParameter])
		return [parameters objectForKey: kNetFSHostParameter];
	
	return nil;
}

# pragma mark Validation
- (BOOL)validateValue:(id)value 
	 forParameterName:(NSString*)paramName 
				error:(NSError**)error
{
	if ([paramName isEqualToString: kNetFSPortParameter ])
	{
		if( [value isKindOfClass: [NSNumber class]] && 
			[(NSNumber*)value intValue] > 1 &&
			[(NSNumber*)value intValue] < 10000 )
		{
			return YES;
		}
		else
		{
			*error = [MFError invalidParameterValueErrorWithParameterName: kNetFSPortParameter
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
	
	if (![parameters objectForKey: kNetFSHostParameter])
	{
		*error = [MFError parameterMissingErrorWithParameterName: kNetFSHostParameter ];
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
	
	if ([output rangeOfString:@"Error resolving hostname"].location != NSNotFound)
	{
		return [MFError errorWithErrorCode:kMFErrorCodeMountFaliure
							   description:@"Remote host could not be found."];
	}
	
	if ([output rangeOfString: @"remote host has disconnected"].location != NSNotFound)
	{
		return [MFError errorWithErrorCode:kMFErrorCodeMountFaliure
							   description:@"Remote host has disconnected."];
	}
	

	return nil;
}

# pragma mark UI
- (NSViewController*)primaryViewController
{
	NSViewController* primaryViewController = [[NSViewController alloc]
											   initWithNibName:@"sshfsConfiguration"
											   bundle: [NSBundle bundleForClass: [self class]]];
	return primaryViewController;
	
}

- (NSViewController*)advancedviewController
{
	NSViewController* advancedviewController = [[NSViewController alloc]
											   initWithNibName:@"sshfsAdvanced"
											   bundle: [NSBundle bundleForClass: [self class]]];
	return advancedviewController;
}

- (NSDictionary*)configurationViewControllers
{
	NSView* emptyView = [NSView new];
	NSViewController* secondViewController = [NSViewController new];
	[secondViewController setView: emptyView];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self primaryViewController], kMFUIMainViewKey,
			[self advancedviewController], kMFUIAdvancedViewKey,
			nil];
}

@end
