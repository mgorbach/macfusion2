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
#import "MFConstants.h"

@interface MFFilesystem(PrivateAPI)

@end

@implementation MFFilesystem


# pragma mark Convenience methods
- (BOOL)isMounted
{
	return [self.status isEqualToString: kMFStatusFSMounted];
}

- (BOOL)isWaiting
{
	return [self.status isEqualToString: kMFStatusFSWaiting];
}

- (BOOL)isUnmounted
{
	return [self.status isEqualToString: kMFStatusFSUnmounted];
}

- (BOOL)isFailedToMount
{
	return [self.status isEqualToString: kMFStatusFSFailed];
}

# pragma mark Accessors

- (NSDictionary*)statusInfo
{
	return [statusInfo copy];
}

- (NSString*)mountPath
{
	return [self valueForParameterNamed: kMFFSMountPathParameter ];
}

- (NSString*)uuid
{
	return [self valueForParameterNamed: KMFFSUUIDParameter ];
}

- (NSString*)status
{
	return [statusInfo objectForKey: kMFSTStatusKey];
}

- (NSString*)name
{
	return [self valueForParameterNamed: kMFFSNameParameter ];
}

- (NSString*)pluginID
{
	return [self valueForParameterNamed: kMFFSTypeParameter ];
}

# pragma mark Setters

- (void)setStatus:(NSString*)status
{
	if (status)
	{
		[statusInfo setObject:status
					   forKey:kMFSTStatusKey];
	}
}

- (void)mount
{
	// Abstract
}

- (void)unmount
{
	// Abstract
}

- (NSMutableDictionary*)parameters
{
	return parameters;
}


- (id)findImpliedValueForParameterNamed:(NSString*)paramName 
						givenParameters:(NSDictionary*)params
{
	if ([parameters objectForKey:paramName])
		return [parameters objectForKey: paramName];
	
	id delegateValue = [delegate impliedValueParameterNamed: paramName
											otherParameters: params];
	if (delegateValue)
	{
		return delegateValue;
	}
	
	NSLog(@"FIND IMPLIED %@", paramName);
	if ([paramName isEqualToString: kMFFSVolumeNameParameter])
	{
		return [parameters objectForKey: kMFFSNameParameter] ?
		[parameters objectForKey: kMFFSNameParameter] :
		@"Unnamed";
	}
	if ([paramName isEqualToString: kMFFSNameParameter])
	{
		return @"Unnamed";
	}
	if ([paramName isEqualToString: kMFFSFilePathParameter])
	{
		return self.uuid;
	}
	
	return nil;
}

- (id)valueForParameterNamed:(NSString*)paramName
{
	//	return [[self parametersWithImpliedValues] objectForKey: paramName];
	return [self findImpliedValueForParameterNamed: paramName
								   givenParameters: parameters ];
}


- (NSArray*)parameterList
{
	NSMutableArray* parameterList = [NSMutableArray array];
	NSArray* delegateParameterList = [delegate parameterList];
	if (delegateParameterList)
	{
		[parameterList addObjectsFromArray: delegateParameterList];
	}

	[parameterList addObject: kMFFSNameParameter ];
	[parameterList addObject: kMFFSMountPathParameter ];
	[parameterList addObject: kMFFSVolumeNameParameter ];
	[parameterList addObject: kMFFSVolumeIconPathParameter ];
	[parameterList addObject: kMFFSFilePathParameter ];
	[parameterList addObject: kMFFSPersistentParameter ];
	
	return [parameterList copy];
}

- (NSMutableDictionary*)fillParametersWithImpliedValues:(NSDictionary*)params
{
	NSMutableDictionary* impliedParameters = [params mutableCopy];
	for(NSString* key in [self parameterList])
	{
		if (![impliedParameters objectForKey: key])
		{
			id value = [self findImpliedValueForParameterNamed: key
											   givenParameters: params];
			if (value)
			{
				[impliedParameters setObject: value
									  forKey: key];
			}
			else
			{
			}
		}
	}
	
	return impliedParameters;
}

- (NSMutableDictionary*)parametersWithImpliedValues
{
	return [self fillParametersWithImpliedValues: parameters];
}

- (NSString*)iconPath
{
	return [self valueForParameterNamed: kMFFSVolumeIconPathParameter ];
}

- (NSString*)descriptionString
{
	NSString* delegateDescription = [delegate descriptionForParameters: 
						  [self parametersWithImpliedValues]];
	return delegateDescription ? delegateDescription : @"No description";
}

- (BOOL)isPersistent
{
	return [[self valueForParameterNamed: kMFFSPersistentParameter]
			boolValue];
}

- (void)setPersistent:(BOOL)b
{
	[self valueForParameterNamed: kMFFSPersistentParameter ];
}

- (NSString*)filePath
{
	return [self valueForParameterNamed: kMFFSFilePathParameter];
}

@end
