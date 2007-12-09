//
//  MFLoggingController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 11/7/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

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
}

+ (MFLoggingController*)sharedController;
- (void)logMessage:(NSString*)message ofType:(int)type sender:(id)sender;

@end
