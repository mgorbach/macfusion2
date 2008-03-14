//
//  MFServerPlugin.m
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

#import "MFServerPlugin.h"
#import "MFPlugin.h"

@implementation MFServerPlugin
+ (MFServerPlugin*)pluginFromBundleAtPath:(NSString*)path
{
	
	MFServerPlugin* plugin = nil;
	plugin = [[MFServerPlugin alloc] initWithPath:path];
	
	return plugin;
}

- (MFPlugin*)initWithPath:(NSString*)path
{
	self = [super init];
	if (self != nil)
	{
		NSBundle* b = [NSBundle bundleWithPath:path];
		bundle = b;
		NSString* plistPath = [b objectForInfoDictionaryKey:@"MFPluginPlist"];
		dictionary = [NSMutableDictionary dictionaryWithContentsOfFile: [b pathForResource:plistPath ofType:nil]];
		if (!dictionary)
		{
			// Failed to read from plist
			return nil;
		}
		
		[dictionary setObject: [b objectForInfoDictionaryKey:@"CFBundleIdentifier"] 
					   forKey: @"BundleIdentifier"];
		
		delegate = [self setupDelegate];
		if(!delegate)
		{
			return nil;
		}
	}
	
	return self;
}


@end
