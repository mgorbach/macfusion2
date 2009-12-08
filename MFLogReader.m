//
//  MFLogReader.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/24/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
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

#import "MFLogReader.h"
#import <asl.h>
#import "MFLogging.h"

@interface MFLogReader(PrivatAPI)
@property(readwrite, retain) NSMutableArray* logMessages;
@end

@implementation MFLogReader

static MFLogReader* sharedReader;

+ (MFLogReader*)sharedReader {
	if (sharedReader == nil) {
		[[self alloc] init];	
	}
	
	return sharedReader;
}

+ (id)allocWithZone:(NSZone*)zone {
	if (sharedReader == nil) 	{
		sharedReader = [super allocWithZone: zone];
		return sharedReader;
	}
	
	return nil;
}

- (void)addASLEntries:(NSArray*)array {
	[self willChangeValueForKey:@"logMessages"];
	[logMessages addObjectsFromArray: array];
	[self didChangeValueForKey:@"logMessages"];
}

- (void)readEntriesFromASL {	
	aslmsg q = asl_new(ASL_TYPE_QUERY);
	aslmsg m;

	asl_set_query(q, ASL_KEY_FACILITY, MF_ASL_SERVICE_NAME, ASL_QUERY_OP_EQUAL);
		
	aslresponse r = asl_search(NULL, q);
	NSMutableArray* logMessagesToAdd = [NSMutableArray array];
	
	while (NULL != (m = aslresponse_next(r))) {
		NSDictionary* dict = dictFromASLMessage(m);
		[logMessagesToAdd addObject: dict];
	}
	
	aslresponse_free(r);
	[self performSelectorOnMainThread:@selector(addASLEntries:) withObject:logMessagesToAdd waitUntilDone:NO];
}

- (void)recordASLMessageDict:(NSDictionary*)messageDict {
	[[self mutableArrayValueForKey: @"logMessages"] addObject:messageDict];
}

- (id)init {
	if (self = [super init]) {
		logMessages = [NSMutableArray array];
		[NSThread detachNewThreadSelector: @selector(readEntriesFromASL)
								 toTarget: self
							   withObject:nil ];
		isRunning = NO;
	}
	
	return self;
}

- (BOOL)isRunning
{
	return isRunning;
}

- (void)start
{
	isRunning = YES;
}


@synthesize logMessages;
@end
