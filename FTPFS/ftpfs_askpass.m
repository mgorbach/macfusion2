//
//  ftpfs_askpass.m
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

#import "MFSecurity.h"
#import "MFClientFS.h"
#import "MFLogging.h"
#import "MFNetworkFS.h"
#define self @"FTPFS_ASKPASS"

int main(int argc, char *argv[])
{
	[[MFLogging sharedLogging] setPrintToStandardOut: NO];
	NSString* token = [[[NSProcessInfo processInfo] environment] objectForKey: @"FTPFS_TOKEN"];
	NSString* password;
	
	if (!token) {
		MFLogS(self, @"Could not find token");
		return -1;
	} else {
		MFClientFS* fs = (MFClientFS *)mfsecGetFilesystemForToken(token);
		if (!fs) {
			MFLogS(self, @"Could not get fs for token"); 
			return -1;
		}
		
		NSDictionary *secrets = mfsecGetSecretsDictionaryForFilesystem(fs);
		if (!secrets) {
			password = mfsecQueryForFSNetworkPassword(fs);
		} else {
			password = [secrets objectForKey:kNetFSPasswordParameter];
		}
		
		if (!password) {
			password = mfsecQueryForFSNetworkPassword(fs);
		}
		
		if (password && [password length] > 0) {
			printf("%s\n", [password UTF8String]);
		}
	}
	
	return 0;
}

