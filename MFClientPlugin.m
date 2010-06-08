//
//  MFClientPlugin.m
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

#import "MFClientPlugin.h"
#import "MFPlugin.h"

@interface MFClientPlugin (PrivateAPI)
- (void)fillInitialData;
@end

@implementation MFClientPlugin
- (id)initWithRemotePlugin:(id)remote {
	self = [super init];
	if (self) {
		remotePlugin = remote;
		[self fillInitialData];
		delegate = [self setupDelegate];
		if (!delegate) {
			return nil;
		}
	}
	
	return self;
}

- (void)fillInitialData {
	bundle = [NSBundle bundleWithPath: [remotePlugin bundlePath]];
}

@end
