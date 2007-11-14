#import <Foundation/Foundation.h>
#import "MFLoggingController.h"
#include "stdarg.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSArray* args = [[NSProcessInfo processInfo] arguments];
	if ([args count] < 2)
	{
		MFPrint(@"No arguments given. Exiting ...");
		return 0;
	}
	else if ([[args objectAtIndex: 1] isEqualToString:@"list"])
	{
		if ([args count] < 3)
		{
			MFPrint(@"Not enough arguments. What to list?");
			return 0;
		}
		else if ([[args objectAtIndex: 2] isEqualToString:@"plugins"])
		{
			MFPrint(@"Listing plugins");
		}
	}
	else
	{
		MFPrint(@"Invalid argument");
		return 0;
	}
	
    [pool drain];
    return 0;
}