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

#import "MFLogging.h"
#import "MFFilesystem.h"

#define LOG_FILE_PATH @"~/Library/Logs/MacFusion2.log"

// Print to logging system
void MFLog(NSString* format, ...)
{
	MFLogging* logger = [MFLogging sharedLogging];
	
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
	[logger logMessage:string ofType:0 object: nil sender:@"MFCORE"]; 
	
    [string release];
}


void MFLogP(int type, NSString* format, ...)
{
	MFLogging* logger = [MFLogging sharedLogging];
	
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
	[logger logMessage:string ofType:type object: nil sender:nil]; 
	
    [string release];
}

void MFLogS(id sender, NSString* format, ...)
{
	MFLogging* logger = [MFLogging sharedLogging];
	
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
	[logger logMessage:string ofType:0 object: nil sender:sender]; 
	
    [string release];
}

void MFLogSO(id sender, id object, NSString* format, ...)
{
	MFLogging* logger = [MFLogging sharedLogging];
	
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
	[logger logMessage:string ofType:0 object:object sender:sender]; 
	
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


@implementation MFLogging

static MFLogging* sharedLogging = nil;

+ (MFLogging*) sharedLogging
{
	if (sharedLogging == nil)
		[[self alloc] init];
	
	return sharedLogging;
}

+ (id)allocWithZone:(NSZone*)zone
{
	if (sharedLogging == nil)
	{
		sharedLogging = [super allocWithZone:zone];
		return sharedLogging;
	}
	
	return nil;
}

- (void)init
{
	fd = -1;
	stdOut = YES;
}

- (void)setupLogFile
{
	if (stdOut)
		aslClient = asl_open(NULL, MF_ASL_SERVICE_NAME, ASL_OPT_STDERR);
	else
		aslClient = asl_open(NULL, MF_ASL_SERVICE_NAME, 0);
	
	fd = open( [[LOG_FILE_PATH stringByExpandingTildeInPath] cStringUsingEncoding: NSUTF8StringEncoding],
			  O_CREAT | O_WRONLY | O_APPEND, S_IRUSR | S_IWUSR );
	asl_add_log_file(aslClient, fd);
	asl_set_filter(aslClient, ASL_FILTER_MASK_UPTO(ASL_LEVEL_INFO));
}

- (void)logMessage:(NSString*)message 
			ofType:(NSInteger)type 
			object:(id)object 
			sender:(id)sender
{
	if (fd == -1)
		[self setupLogFile];
	
	message = [message stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	aslmsg m = asl_new(ASL_TYPE_MSG);
	asl_set(m, ASL_KEY_FACILITY, MF_ASL_SERVICE_NAME);
	if ([sender isKindOfClass: [MFFilesystem class]])
		asl_set(m, ASL_KEY_UUID, [[(MFFilesystem*)sender uuid] cStringUsingEncoding: NSUTF8StringEncoding]);
	if ([object isKindOfClass: [MFFilesystem class]])
		asl_set(m, ASL_KEY_UUID, [[(MFFilesystem*)object uuid] cStringUsingEncoding: NSUTF8StringEncoding]);
	asl_set(m, ASL_KEY_SUBSYSTEM, [[sender description] cStringUsingEncoding: NSUTF8StringEncoding]);
	asl_log(aslClient, m, ASL_LEVEL_NOTICE, [message cStringUsingEncoding: NSUTF8StringEncoding]);
	return;
}

- (void)setPrintToStandardOut:(BOOL)b
{
	stdOut = b;
}

- (void)finalize
{
	asl_close(aslClient);
	close(fd);
	[super finalize];
}

@end
