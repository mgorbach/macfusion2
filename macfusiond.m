#import <Foundation/Foundation.h>
#import "MFMainController.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	MFMainController* primaryController = [MFMainController sharedController];
	[primaryController initialize];
	
    [pool drain];
    return 0;
}


