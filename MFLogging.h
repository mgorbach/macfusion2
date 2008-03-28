//
//  MFLoggingController.h
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

#import <Cocoa/Cocoa.h>
#import <asl.h>

#define MF_ASL_SERVICE_NAME "org.mgorbach.macfusion"
#define ASL_KEY_SUBSYSTEM "Subsystem"
#define ASL_KEY_UUID "UUID"

#define kMFLogKeySender @"Sender"
#define kMFLogKeyUUID @"UUID"
#define kMFLogKeySubsystem @"Subsystem"
#define kMFLogKeyMessage @"Message"
#define kMFLogKeyTime @"Time"



enum MFLogType {
	kMFLogTypeCore,
	kMFLogTypeEvent,
	kMFLogTypePlugin
};

void MFLogP(int type, NSString* format, ...);
void MFLog(NSString* format, ...);
void MFPrint(NSString* format, ...);
void MFLogS(id sender, NSString* format, ...);
void MFLogSO(id sender, id object, NSString* format, ...);

@interface MFLogging : NSObject {
	NSFileHandle* fileHandle;
	BOOL stdOut;
	aslclient aslClient;
	int fd;
	id delegate;
	NSDateFormatter* formatter;
}

+ (MFLogging*)sharedLogging;
- (void)logMessage:(NSString*)message 
			ofType:(NSInteger)type 
			object:(id)object 
			sender:(id)sender;
- (void)setPrintToStandardOut:(BOOL)b;

NSDictionary* dictFromASLMessage(aslmsg m);
NSString* headerStringForASLMessageDict(NSDictionary* dict);

@property(retain, readwrite) id delegate;
@end
