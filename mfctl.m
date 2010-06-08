/*
 *  mfctl.m
 *  MacFusion2
 */

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

#import <Foundation/Foundation.h>
#import "MFLogging.h"
#import "MFServerProtocol.h"
#import "MFClient.h"
#import "MFClientFS.h"

#include "stdarg.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSArray* args = [[NSProcessInfo processInfo] arguments];
	MFClient* client = [MFClient sharedClient];
	BOOL ok = [client setup];
	NSArray* filesystems = [client filesystems];
//	NSArray* plugins = [client plugins];
	
	if (!ok)
	{
		MFPrint(@"Can not establish communication to the server. Quitting.");
		return -1;
	}
	
	if ([args count] < 2)
	{
		MFPrint(@"No arguments given. Exiting!");
		return 0;
	}
	else if ([[args objectAtIndex: 1] isEqualToString:@"status"])
	{
		for (MFClientFS* fs in filesystems)
		{
			MFPrint(@"Filesystem %@", fs.uuid);
			MFPrint(@"Parameters: %@", fs.parameters);
			MFPrint(@"Statusinfo: %@", fs.statusInfo);
		}
	}
	else if ([[args objectAtIndex: 1] isEqualToString:@"mount"])
	{
		if([args count] == 3)
		{
			NSString* mountTarget = [args objectAtIndex: 2];
			BOOL hit = NO;;
			for(MFClientFS* fs in filesystems)
			{
				if ([[fs name] isEqualToString: mountTarget])
				{
					MFPrint(@"Mounting %@", mountTarget);
					[fs mount];
					hit = YES;
				}
			}
			if (!hit)
			{
				MFPrint(@"Failed to mount. No such filesystem");
			}
		}
		else
		{
			MFPrint(@"Wrong number of arguments for mount command.");
		}
	}
	else if ([[args objectAtIndex: 1] isEqualToString:@"unmount"])
	{
		if([args count] == 3)
		{
			NSString* mountTarget = [args objectAtIndex: 2];
			BOOL hit = NO;;
			for(MFClientFS* fs in filesystems)
			{
				if ([[fs name] isEqualToString: mountTarget])
				{
					MFPrint(@"Unmounting %@", mountTarget);
					[fs unmount];
					hit = YES;
				}
			}
			if (!hit)
			{
				MFPrint(@"Failed to unmount. No such filesystem");
			}
		}
		else
		{
			MFPrint(@"Wrong number of arguments for unmount command.");
		}
	}
	else
	{
		MFPrint(@"Invalid first argument. Exiting!");
	}

    [pool drain];
    return 0;
}



