//
//  macfusionAgent.m
//  Macfusion2
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MFMainController.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	MFMainController* primaryController = [MFMainController sharedController];
	[primaryController initialize];
	
    [pool drain];
    return 0;
}


