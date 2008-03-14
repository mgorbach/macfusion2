//
//  MFError.m
//  MacFusion2
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//      http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
