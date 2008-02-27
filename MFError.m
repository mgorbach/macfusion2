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
							   code: kMFErrorCodeInvalidParameterValue
						   userInfo: errorDict];
}


- (NSString*)localizedDescription
{
	NSString* paramName = [[self userInfo] objectForKey: kMFErrorParameterKey];
	NSString* faliureReason = [[self userInfo] objectForKey: NSLocalizedFailureReasonErrorKey ];
	if ( ![[self userInfo] objectForKey: NSLocalizedDescriptionKey ] &&  paramName)
	{

		if ([self code] == kMFErrorCodeMissingParameter)
		{
			return [NSString stringWithFormat: @"Missing required value for %@",
					 paramName ];
		}
		if ([self code] == kMFErrorCodeInvalidParameterValue)
		{
			return [NSString stringWithFormat: @"Invalid value for %@\n%@",
					[[self userInfo] objectForKey: kMFErrorParameterKey],
					faliureReason ? faliureReason : @"" ];
		}
	}
	
	return [super localizedDescription];
}

+ (MFError*)errorWithErrorCode:(NSInteger)code 
				   description:(NSString*)description
{
	return [MFError errorWithDomain:kMFErrorDomain
							   code:code
						   userInfo: [NSDictionary dictionaryWithObject: description
																 forKey: NSLocalizedDescriptionKey ] ];
}

@end
