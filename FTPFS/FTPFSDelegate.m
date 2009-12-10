//
//  FTPFSDelegate.m
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

#import "FTPFSDelegate.h"
#import "MFConstants.h"
#import "MGUtilities.h"
#import "MFError.h"
#import "MFNetworkFS.h"
#import "MFSecurity.h"
#import <Security/Security.h>
#import "MFClientFSUI.h"

static NSString *primaryViewControllerKey = @"sshfsPrimaryView";
static NSString *advancedViewControllerKey = @"sshfsAdvancedView";


@implementation FTPFSDelegate

#pragma mark Plugin Info
- (NSString *)askpassPath {
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"ftpfs_askpass" ofType:nil inDirectory:nil];
}


- (NSString *)executablePath {
	return [[NSBundle bundleForClass:[self class]] pathForResource:@"curlftpfs_static_mg" ofType:nil inDirectory:nil];
}

- (NSArray *)secretsClientsList {
	return [NSArray arrayWithObjects:[self askpassPath], nil];
}

#pragma mark Mounting
- (NSArray *)taskArgumentsForParameters:(NSDictionary *)parameters {
	NSMutableArray *arguments = [NSMutableArray array];
	[arguments addObject:[NSString stringWithFormat:@"%@:%@/%@", [parameters objectForKey:kNetFSHostParameter], [parameters objectForKey:kNetFSPortParameter], [parameters objectForKey:kNetFSDirectoryParameter]]];
	
	[arguments addObject:[parameters objectForKey:kMFFSMountPathParameter]];
	
	if ([parameters objectForKey:kNetFSUserParameter]) {
		[arguments addObject:[NSString stringWithFormat:@"-ouser=%@", [parameters objectForKey:kNetFSUserParameter]]];
	}
	
	[arguments addObject:[NSString stringWithFormat:@"-ovolname=%@", [parameters objectForKey:kMFFSVolumeNameParameter]]];
	[arguments addObject:@"-f"];
	[arguments addObject:[NSString stringWithFormat:@"-ovolicon=%@", [parameters objectForKey:kMFFSVolumeIconPathParameter]]];
	[arguments addObject:[NSString stringWithFormat:@"-odefer_permissions"]];
	return [arguments copy];
}

- (NSDictionary *)taskEnvironmentForParameters:(NSDictionary *)params {
	NSMutableDictionary* env = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
	[env setObject:mfsecTokenForFilesystemWithUUID([params objectForKey:KMFFSUUIDParameter]) forKey:@"FTPFS_TOKEN"];
	[env setObject:[self askpassPath] forKey:@"FTPFS_ASKPASS"];
	
	return [env copy];
}

# pragma mark Quickmount
- (NSArray *)urlSchemesHandled {
	return [NSArray arrayWithObjects:@"ftp", nil];
}

- (NSDictionary *)parameterDictionaryForURL:(NSURL *)url error:(NSError **)error {
	NSString *host = [url host];
	NSString *userName = [url user];
	NSNumber *port = [url port];
	NSString *directory = [url relativePath];
	
	NSMutableDictionary *params = [[self defaultParameterDictionary] mutableCopy];
	if (host) {
		[params setObject:host forKey:kNetFSHostParameter];
	} 
	if (userName) {
		[params setObject:userName forKey:kNetFSUserParameter];
	}
	if (port) {
		[params setObject:port forKey:kNetFSPortParameter];
	}
	if (directory) {
		[params setObject:directory forKey:kNetFSDirectoryParameter];
	}
	
	return [params copy];
}

# pragma mark Parameters
- (NSArray *)parameterList {
	return [NSArray arrayWithObjects:kNetFSUserParameter, kNetFSHostParameter, kNetFSDirectoryParameter, kNetFSUserParameter,
			kNetFSPortParameter, kNetFSProtocolParameter, nil ];
}

- (NSArray*)secretsList {
	return [NSArray arrayWithObjects:kNetFSPasswordParameter, nil];
}

- (NSDictionary *)defaultParameterDictionary {
	NSDictionary *defaultParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"", kNetFSDirectoryParameter, [NSNumber numberWithInt:21], kNetFSPortParameter, [NSNumber numberWithInt:kSecProtocolTypeFTP], kNetFSProtocolParameter, nil];
	
	return defaultParameters;
}

- (NSString*)descriptionForParameters:(NSDictionary *)parameters {
	NSString *description = nil;
	if (![parameters objectForKey:kNetFSHostParameter]) {
		description = @"No host specified";
	} else {
		if( [parameters objectForKey:kNetFSUserParameter] && ![[parameters objectForKey:kNetFSUserParameter] isEqualTo:NSUserName()]) {
			description = [NSString stringWithFormat:@"%@@%@", [parameters objectForKey:kNetFSUserParameter], [parameters objectForKey:kNetFSHostParameter]];
		} else {
			description = [NSString stringWithString:[parameters objectForKey:kNetFSHostParameter]];
		}
	}
	
	return description;
}

- (id)impliedValueParameterNamed:(NSString*)parameterName otherParameters:(NSDictionary*)parameters {
	if ([parameterName isEqualToString:kMFFSMountPathParameter] && [parameters objectForKey:kNetFSHostParameter]) {
		NSString *mountBathBase = [parameters objectForKey:kMFFSNameParameter] ? [parameters objectForKey:kMFFSNameParameter] : [parameters objectForKey:kNetFSHostParameter];
		
		NSString *mountPath = [NSString stringWithFormat:@"/Volumes/%@", mountBathBase];
		return mountPath;
	}
	
	if ([parameterName isEqualToString:kMFFSVolumeNameParameter] && [parameters objectForKey:kNetFSHostParameter]) {
		return [parameters objectForKey:kNetFSHostParameter];
	}
	
	if ([parameterName isEqualToString:kMFFSVolumeIconPathParameter]) {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"ftpfs_icon"];
	}
	
	if ([parameterName isEqualToString:kMFFSVolumeImagePathParameter]) {
		return [[NSBundle bundleForClass:[self class]] pathForImageResource:@"ftpfs"];
	}
	
	if ([parameterName isEqualToString:kMFFSNameParameter]) {
		return [parameters objectForKey:kNetFSHostParameter];
	}
	
	return nil;
}

# pragma mark Validation
- (BOOL)validateValue:(id)value forParameterName:(NSString *)paramName error:(NSError **)error {
	if ([paramName isEqualToString:kNetFSPortParameter ]) {
		NSNumber *converted = [NSNumber numberWithInt:[value intValue]];
		if( [converted isKindOfClass:[NSNumber class]] && [converted intValue] > 0 && [converted intValue] < 65535 ) {
			return YES;
		} else {
			if (error) {
				*error = [MFError invalidParameterValueErrorWithParameterName:kNetFSPortParameter value:value description:@"Must be positive number < 10000"];
			}
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)validateParameters:(NSDictionary *)parameters error:(NSError **)error {
	for (NSString* paramName in [parameters allKeys]) {
		BOOL ok = [self validateValue:[parameters objectForKey:paramName] forParameterName:paramName error:error];
		
		if (!ok) {
			return NO;
		}
	}
	
	if (![parameters objectForKey:kNetFSHostParameter]) {
		if(error) {
			*error = [MFError parameterMissingErrorWithParameterName:kNetFSHostParameter];
		}
		return NO;
	}
	
	return YES;
}

- (NSError *)errorForParameters:(NSDictionary *)parameters output:(NSString *)output {
	// We need better errors here ...
	return nil;
}

# pragma mark UI
- (NSViewController *)primaryViewController {
	NSViewController* primaryViewController = [[NSViewController alloc] initWithNibName:@"ftpfsConfiguration" bundle:[NSBundle bundleForClass:[self class]]];
	[primaryViewController setTitle:@"FTP"];
	return primaryViewController;
}

- (NSViewController *)advancedviewController {
	return nil;
}

- (NSArray *)viewControllerKeys {
	return [NSArray arrayWithObjects:primaryViewControllerKey, kMFUIMacfusionAdvancedViewKey,nil];
}

- (NSViewController *)viewControllerForKey:(NSString *)key {
	if (key == primaryViewControllerKey) {
		return [self primaryViewController];
	} else if (key == advancedViewControllerKey) {
		return [self advancedviewController];
	}
	
	return nil;
}

@end
