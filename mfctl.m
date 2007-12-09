#import <Foundation/Foundation.h>
#import "MFLoggingController.h"
#import "MFServerProtocol.h"
#import "MFFilesystemController.h"
#import "MFFilesystem.h"

#include "stdarg.h"

static id serverObject = nil;

BOOL connectToServer(void)
{
	serverObject = [NSConnection rootProxyForConnectionWithRegisteredName:@"macfusion" host:nil];
	[serverObject setProtocolForProxy:@protocol(MFServerProtocol)];
	if (serverObject)
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

void listPlugins(void)
{
	return;
}

void listFilesystems(void)
{
	if (connectToServer())
	{
		[serverObject sendStatus];
		NSArray* filesystems = [[serverObject filesystemController] filesystems];
		NSMutableArray* stringsToPrint = [NSMutableArray array];
		for(MFFilesystem* fs in filesystems)
		{
			[stringsToPrint addObject:
			 [NSString stringWithFormat:@"%@: %@",
			  [fs valueForKey:@"Volume Name"],
			  [fs valueForKey:@"status"]]];
		}
		MFPrint(@"%@", serverObject);
		MFPrint(@"%@", stringsToPrint);
	}
	else
	{
		MFPrint(@"Can not connect to macfusion agent. Exiting!");
		exit(-1);
	}
}

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSArray* args = [[NSProcessInfo processInfo] arguments];

	
	if ([args count] < 2)
	{
		MFPrint(@"No arguments given. Exiting!");
		return 0;
	}
	else if ([[args objectAtIndex: 1] isEqualToString:@"list"])
	{
		if ([args count] < 3)
		{
			MFPrint(@"Not enough arguments. What to list?");
			return -1;
		}
		if ([[args objectAtIndex: 2] isEqualToString:@"filesystems"])
		{
			listFilesystems();
		}
		else if ([[args objectAtIndex: 2] isEqualToString:@"plugins"])
		{
			listPlugins();
		}
		else
		{
			MFPrint(@"Syntax error: 'list' command must be followed by 'plugins' \
					or 'filesystems'. Exiting!");
			return -1;
		}
	}
	else
	{
		MFPrint(@"Invalid first argument. Exiting!");
	}

    [pool drain];
    return 0;
}



