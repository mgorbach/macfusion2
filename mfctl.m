#import <Foundation/Foundation.h>
#import "MFLoggingController.h"
#import "MFServerProtocol.h"
#import "MFClient.h"
#import "MFClientFS.h"

#include "stdarg.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSArray* args = [[NSProcessInfo processInfo] arguments];
	MFClient* client = [MFClient sharedClient];
	BOOL ok = [client establishCommunication];
	[client fillInitialStatus];
	
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



