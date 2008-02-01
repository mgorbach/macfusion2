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

- (NSDictionary*)parameters
{
	// We want an immutable dictionary
	return [parameters copy];
}

- (NSDictionary*)statusInfo
{
	return [statusInfo copy];
}

/*
- (id)valueForUndefinedKey:(NSString*)key
{
	id value = [parameters valueForKey:key];
	if (value)
	{
		return value;
	}
	
	return [super valueForUndefinedKey:key];
}
*/

- (NSString*)mountPath
{
	return [parameters objectForKey:@"Mount Path"];
}

- (NSString*)uuid
{
	return [statusInfo objectForKey:@"uuid"];
}

- (NSString*)status
{
	return [statusInfo objectForKey:@"status"];
}

- (NSString*)name
{
	return [parameters objectForKey:@"name"];
}

- (NSString*)pluginID
{
	return [parameters objectForKey:@"Type"];
}

# pragma mark Setters

- (void)setStatus:(NSString*)status
{
	if (status)
	{
		[statusInfo setObject:status
					   forKey:@"status"];
	}
}

- (NSString*)descriptionString
{
	return [parameters objectForKey:@"Description"];
}

- (void)mount
{
	// Abstract
}

- (void)unmount
{
	// Abstract
}

@end
