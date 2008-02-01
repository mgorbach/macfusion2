//
//  MFPlugin.m
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFPlugin.h"
#import "MFConstants.h"

@interface MFPlugin(PrivateAPI)
- (id <MFFSDelegateProtocol>)setupDelegate;
@end

@implementation MFPlugin

- (id) init
{
	self = [super init];
	if (self != nil) {
	}
	return self;
}


- (NSString*)nibName
{
	return [self.bundle objectForInfoDictionaryKey:@"MFPluginNibName"];
}

- (NSString*)ID
{
	return [self.dictionary objectForKey: @"BundleIdentifier"];
}

- (NSString*)bundlePath
{
	return [bundle bundlePath];
}

- (NSString*)shortName
{
	return [bundle objectForInfoDictionaryKey: kMFPluginShortNameKey];
}

- (NSString*)longName
{
	return [bundle objectForInfoDictionaryKey: kMFPluginLongNameKey];
}

- (id <MFFSDelegateProtocol>)setupDelegate
{
	id thisDelegate;
	NSString* fsDelegateClassName = [bundle objectForInfoDictionaryKey:@"MFFSDelegateClassName"];
	if (fsDelegateClassName == nil)
	{
		MFLogS(self, @"Failed to create delegate for plugin at path %@. No delegate class name specified.",
			   [bundle bundlePath]);
	}
	else 
	{
		BOOL success = [bundle load];
		if (success)
		{
			Class FSDelegateClass = NSClassFromString(fsDelegateClassName);
			thisDelegate = [[FSDelegateClass alloc] init];
			
			if (!thisDelegate)
			{
				
				MFLogS(self, @"Failed to create delegate for plugin at pat %@. Specified delegate class could not \
					   be instantiated");

			}
		}
	}
	
	return thisDelegate;
}

- (id <MFFSDelegateProtocol>)delegate
{
	return delegate;
}

@synthesize dictionary, bundle;
@end
