//
//  MFError.m
//  MacFusion2
//
//  Created by Michael Gorbach on 2/14/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFError.h"
#import "MFConstants.h"

@implementation MFError

+ (MFError*)parameterMissingErrorWithParameterName:(NSString*)parameter
{
	return [MFError errorWithDomain:kMFErrorDomain
							   code:kMFErrorCodeMissingParameter
						   userInfo: [NSDictionary dictionaryWithObject: parameter
																 forKey: kMFErrorParameterKey ]];
}


+ (MFError*)invalidParameterValueErrorWithParameterName:(NSString*)parameter
												  value:(id)value
											description:(NSString*)description
{
	NSDictionary* errorDict = [NSDictionary dictionaryWithObjectsAndKeys: 
							   parameter, kMFErrorParameterKey,
							   value, kMFErrorValueKey,
							   description, NSLocalizedFailureReasonErrorKey,
							   nil];
	return [MFError errorWithDomain: kMFErrorDomain
							   code:kMFErrorInvalidParameterValue
						   userInfo: errorDict];
}


- (NSString*)localizedDescription
{
	if ( ![[self userInfo] objectForKey: NSLocalizedDescriptionKey ] && 
		[[self userInfo] objectForKey: kMFErrorParameterKey])
	{
		if ([self code] == kMFErrorCodeMissingParameter)
		{
			return [NSString stringWithFormat: @"Missing required value for paramter %@",
					[[self userInfo] objectForKey: kMFErrorParameterKey] ];
		}
		if ([self code] == kMFErrorInvalidParameterValue)
		{
			return [NSString stringWithFormat: @"Invalid value for parameter %@: %@",
					[[self userInfo] objectForKey: kMFErrorParameterKey],
					[[self userInfo] objectForKey: NSLocalizedFailureReasonErrorKey ] ];
		}
	}
	
	return [super localizedDescription];
}

@end
