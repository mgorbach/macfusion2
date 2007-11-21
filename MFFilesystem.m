//
//  MFFilesystem.m
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFFilesystem.h"
//#import "MFPluginController.h"
#import "MFPlugin.h"

@interface MFFilesystem(PrivateAPI)
- (NSMutableDictionary*)fullParametersWithDictionary: (NSDictionary*)fsParams;
- (NSArray*)taskArgumentList;
@end

@implementation MFFilesystem

+ (MFFilesystem*)filesystemFromParameters:(NSDictionary*)parameters plugin:(MFPlugin*)p
{
	MFFilesystem* fs = [[MFFilesystem alloc] initWithParameters: parameters plugin: p];
	return fs;
}

- (MFFilesystem*)initWithParameters:(NSDictionary*)params plugin:(MFPlugin*)p
{
	self = [super init];
	plugin = p;
	parameters = [self fullParametersWithDictionary: params];
	return self;
}


- (NSString*)pluginID
{
	return [parameters objectForKey:@"Type"];
}

- (NSDictionary*)parameterDictionary
{
	// We want an immutable dictionary
	return [parameters copy];
}

- (NSMutableDictionary*)fullParametersWithDictionary:(NSDictionary*)fsParams
{
	NSDictionary* defaultParams = [plugin defaultParameterDictionary];
	NSMutableDictionary* params = [NSMutableDictionary dictionary];
	
	for(NSString* parameterKey in [defaultParams keyEnumerator])
	{
		if ([fsParams objectForKey:parameterKey] != nil)
		{
			// The fs specifies a value for this parameter, take it.
			// Validation per-value goes here
			[params setObject: [fsParams objectForKey:parameterKey]
					forKey: parameterKey];
		}
		else 
		{
			// The fs doesn't specify a value for this parameter.
			// Use the default
			[params setObject: [defaultParams objectForKey:parameterKey]
					forKey: parameterKey];
		}
			
	}
	
	return params;
}

- (NSArray*)taskArgumentList
{
	NSMutableString* formatString = [[[self plugin] inputFormatString] mutableCopy];
	NSArray* argParameters;
	NSString* token;
	
	for(NSString* parameterKey in parameters)
	{
		// Filter for only those parameters that have tokens in the input format string
		if ((token = [[self plugin] tokenForParameter: parameterKey]) != nil)
		{
			// Place the token into place
			// TODO: SECURITY: Watch for instances of tokens in user input
			// TODO: Value typing
			NSString* searchString = [NSString stringWithFormat:@"[%@]", token];
			id value = [parameters objectForKey:parameterKey];
			NSString* stringValue;
			if ([value isKindOfClass: [NSString class]])
			{
				stringValue = value;
			}
			if ([value isKindOfClass: [NSNumber class]])
			{
				stringValue = [(NSNumber*)value stringValue];
			}
			
			[formatString replaceOccurrencesOfString:searchString 
										  withString:value 
											 options:NSLiteralSearch
											   range:NSMakeRange(0, [formatString length])];
		}
		
		// TODO: Handle options here
		// TODO: Handle environment here
			
	}
	
	argParameters = [formatString componentsSeparatedByString:@" "];
	return argParameters;
}

- (NSTask*)taskForLaunch
{
	return nil;
}

- (MFPlugin*)plugin
{
	if (plugin)
		return plugin;
	else
	{
		MFPrint(@"Plugin empty!");
		return nil;
	}
}

@end
