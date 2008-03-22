//
//  MFPlugin.m
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

#import "MFPlugin.h"
#import "MFConstants.h"

@interface MFPlugin(PrivateAPI)

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
	return [[self bundle] bundleIdentifier];
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
	id thisDelegate = nil;
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

@synthesize bundle;
@end
