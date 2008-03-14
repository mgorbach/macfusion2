//
//  MFLoggingController.m
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

#import "MFLoggingController.h"
#define LOG_FILE_PATH @"~/Library/Logs/MacFusion2.log"

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

void MFLogS(id sender, NSString* format, ...)
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
	[logger logMessage:string ofType:0 sender:sender]; 
	
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

- (void)registerNotifications
{
	// We need notifications here, but what about the differnece between
	// client and server processes?
}

- (void)init
{
	// Nothing here yet
	stdOut = YES;
}

- (NSString*)descriptionForObject:(id)object
{
	if (object == nil)
	{
		return @"NILL";
	}
	else
	{
		return [object description];
	}
}

- (NSFileHandle*)handleForLogfile
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* filePath = [ LOG_FILE_PATH stringByExpandingTildeInPath ];
	
	if (![fm fileExistsAtPath:filePath])
	{
		[fm createFileAtPath:filePath contents:nil attributes:nil];
	}
	
	fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
	return fileHandle;
}

- (void)logMessageToFile:(NSString*)message ofType:(int)type sender:(id)sender
{
	NSString* description = [self descriptionForObject: sender];
	NSString* writeString = [NSString stringWithFormat: @"%@: %@\n",
							 description, message];
	
	NSFileHandle* handle = [self handleForLogfile];
	[handle truncateFileAtOffset: [fileHandle seekToEndOfFile]];
	[handle writeData: [writeString dataUsingEncoding:NSUTF8StringEncoding]];
	[handle synchronizeFile];
}

- (void)logMessage:(NSString*)message ofType:(int)type sender:(id)sender
{
	message = [message stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	[self logMessageToFile:message ofType:type sender:sender];
	if (stdOut)
	{
		if (!sender)
			printf("%s\n", [message cStringUsingEncoding:NSUTF8StringEncoding]);
		else
			printf("%s: %s\n", [[sender description] cStringUsingEncoding:NSUTF8StringEncoding],
				   [message cStringUsingEncoding: NSUTF8StringEncoding]);
	}

	return;
}

- (void)setPrintToStandardOut:(BOOL)b
{
	stdOut = b;
}

- (void)finalize
{
	[fileHandle closeFile];
	[super finalize];
}

@end
