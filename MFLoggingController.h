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
enum MFLogType {
	kMFLogTypeCore,
	kMFLogTypeEvent,
	kMFLogTypePlugin
};

void MFLogP(int type, NSString* format, ...);
void MFLog(NSString* format, ...);
void MFPrint(NSString* format, ...);

@interface MFLoggingController : NSObject {
	NSFileHandle* fileHandle;
	BOOL stdOut;
}

+ (MFLoggingController*)sharedController;
- (void)logMessage:(NSString*)message ofType:(int)type sender:(id)sender;
- (void)setPrintToStandardOut:(BOOL)b;

@end
