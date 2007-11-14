//
//  MFLoggingController.m
//  MacFusion2
//
//  Created by Michael Gorbach on 11/7/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFLoggingController.h"

// Print to logging system
void MFLog(NSString* format, ...)
{
	MFLoggingController* logger = [MFLoggingController sharedController];
	
	// get a reference to the arguments on the stack that follow
    // the format paramter
    va_list argList;
    va_start (argList, format);
	
    // NSString luckily provides us with this handy method which
    // will do all the work for us, including %@
    NSString *string;
    string = [[NSString alloc] initWithFormat: format
									arguments: argList];
    va_end  (argList);
	[logger logMessage:string ofType:kMFLogTypeCore sender:nil]; 
	
    [string release];
}


void MFLogP(int type, NSString* format, ...)
{
	MFLoggingController* logger = [MFLoggingController sharedController];
	
	// get a reference to the arguments on the stack that follow
    // the format paramter
    va_list argList;
    va_start (argList, format);
	
    // NSString luckily provides us with this handy method which
    // will do all the work for us, including %@
    NSString *string;
    string = [[NSString alloc] initWithFormat: format
									arguments: argList];
    va_end  (argList);
	[logger logMessage:string ofType:type sender:nil]; 
	
    [string release];
}
 

// Print directly to console
void MFPrint(NSString* format, ...)
{
	// get a reference to the arguments on the stack that follow
    // the format paramter
    va_list argList;
    va_start (argList, format);
	
    // NSString luckily provides us with this handy method which
    // will do all the work for us, including %@
    NSString *string;
    string = [[NSString alloc] initWithFormat: format
									arguments: argList];
    va_end  (argList);
	printf("%s\n", [string cStringUsingEncoding:NSASCIIStringEncoding]);
	
    [string release];
}


@implementation MFLoggingController

static MFLoggingController* sharedController = nil;

+ (MFLoggingController*) sharedController
{
	if (sharedController == nil)
		[[self alloc] init];
	
	return sharedController;
}

+ (id)allocWithZone:(NSZone*)zone
{
	if (sharedController == nil)
	{
		sharedController = [super allocWithZone:zone];
		return sharedController;
	}
	
	return nil;
}

- (void)init
{
	// Nothing here yet
}

- (void)logMessage:(NSString*)message ofType:(int)type sender:(id)sender
{
	return;
}

@end
