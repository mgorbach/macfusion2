//
//  MFCore.m
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

#import "MFCore.h"
#define self @"MFCORE"

NSString* mfcMainBundlePath()
{
	NSString* mybundleID = [[NSBundle mainBundle] bundleIdentifier];
	NSString* pathToReturn = nil;
	
	if ( [mybundleID isEqualToString: kMFMainBundleIdentifier] )
		pathToReturn = [[NSBundle mainBundle] bundlePath];
	if ( [mybundleID isEqualToString: kMFAgentBundleIdentifier] ||
		[mybundleID isEqualToString: kMFMenulingBundleIdentifier] )
	{
		NSString* relativePath = @"/../../../";
		NSString* fullPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent: relativePath];
		pathToReturn = [fullPath stringByStandardizingPath];
	}
	
	return pathToReturn;
}

NSString* mfcMenulingBundlePath()
{
	NSString* mainBundlePath = mfcMainBundlePath();
	return [mainBundlePath stringByAppendingPathComponent:@"/Contents/Resources/MacfusionMenuling.app"];
}

NSString* mfcAgentBundlePath()
{
	NSString* mainBundlePath = mfcMainBundlePath();
	return [mainBundlePath stringByAppendingPathComponent:@"/Contents/Resources/macfusionAgent.app"];
}

NSArray* mfcSecretClientsForFileystem( MFFilesystem* fs )
{
	NSMutableArray* clientList = [NSMutableArray array];
	if ([[fs delegate] respondsToSelector:@selector(secretsClientsList)])
	{
		NSArray* fsList = [[fs delegate] secretsClientsList];
		if (fsList)
			[clientList addObjectsFromArray: fsList];
	}
	
	NSBundle* mainUIBundle = [NSBundle bundleWithPath: mfcMainBundlePath()];
	[clientList addObject: [mainUIBundle executablePath]];
	NSBundle* menulingUIBundle = [NSBundle bundleWithPath: mfcMenulingBundlePath()];
	[clientList addObject: [menulingUIBundle executablePath]];
	[clientList addObject: mfcAgentBundlePath()];
	return [clientList copy];
}

BOOL mfcGetStateOfLoginItemWithPath( NSString* path )
{
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	BOOL present = FALSE;
	UInt32 seedValue;
	NSArray  *loginItems = (NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, &seedValue);
	for(id loginItem in loginItems)
	{
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)loginItem;
		NSURL* theURL = [NSURL new];
		LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*)&theURL, NULL);
		present = ([[theURL path] isEqualToString: path]);
		if (present)
			break;
	}
	
	CFRelease(loginItemsRef);
	return present;
}

BOOL mfcGetStateForAgentLoginItem()
{
	NSString* agentPath  = mfcAgentBundlePath();
	return mfcGetStateOfLoginItemWithPath( agentPath );
}

BOOL mfcSetStateForAgentLoginItem(BOOL state)
{
	NSString* agentPath = mfcAgentBundlePath();
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (mfcGetStateOfLoginItemWithPath(agentPath) == state)
		return NO;
	
	UInt32 seedValue;
	NSArray  *loginItems = (NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, &seedValue);
	for(id loginItem in loginItems)
	{
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)loginItem;
		NSURL* theURL = [NSURL new];
		LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*)&theURL, NULL);
		NSString* checkPath = [[theURL path] lastPathComponent];
		if ([checkPath isLike: @"*macfusionAgent*"])
		{
			LSSharedFileListItemRemove(loginItemsRef, itemRef);
		}
	}
	
	if(state == YES)
	{
		LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemBeforeFirst, NULL, NULL, 
									  (CFURLRef)[NSURL fileURLWithPath: agentPath], NULL, NULL);
	}
	
	CFRelease(loginItemsRef);
	return YES;
}

NSString* mfcGetMacFuseVersion()
{
	NSDictionary* fuseData = [NSDictionary dictionaryWithContentsOfFile: 
							  @"/Library/Filesystems/fusefs.fs/Contents/Info.plist"];
	return [fuseData objectForKey: @"CFBundleVersion"];
}

BOOL mfcClientIsUIElement()
{
	NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
	BOOL uiElement = [[info objectForKey: @"LSUIElement"] boolValue];
	return uiElement;
}

void mfcLaunchAgent()
{
	NSString* path = mfcAgentBundlePath();
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObject: path]];
}

void mfcLaunchMenuling()
{
	NSString* path = mfcMenulingBundlePath();
	[NSTask launchedTaskWithLaunchPath:@"/usr/bin/open" arguments:[NSArray arrayWithObject: path]];
}

// Checks the integrity of Macfusion2's multi-process system
// Make sure we are all running from the same bundle and speaking the same language
void mfcCheckIntegrity()
{
	ProcessSerialNumber currentPSN = { 0, kNoProcess };
	CFStringRef processName;
	FSRef bundleFSRef;
	OSErr error;
	id runningAgentPath=nil;
	id runningMenulingPath=nil;
	
	pid_t runningAgentPID=0, runningMenulingPID=0;
	
	while(GetNextProcess( &currentPSN ) == noErr
		  && currentPSN.lowLongOfPSN != kNoProcess )
	{
		NSString* processPath;
		CopyProcessName( &currentPSN, &processName );
		pid_t processPID;
		
		if ( [ (NSString*)processName isEqualToString: @"macfusionAgent" ] || 
			 [ (NSString*)processName isEqualToString: @"macfusionMenuling"] )
		{
			error = GetProcessBundleLocation( &currentPSN, &bundleFSRef);
			GetProcessPID( &currentPSN , &processPID);
			
			if (error == noErr)
			{
				CFURLRef bundleURLRef = CFURLCreateFromFSRef( kCFAllocatorDefault, &bundleFSRef);
				processPath = [ (NSURL*)bundleURLRef path ];
				CFRelease( bundleURLRef );
			}
			else
			{
				processPath = (NSString*)[NSNull null]; 
				// Set the processPath to NSNull if we failed getting it
				// This can happen if the process is running from the trash (i.e. it's been deleted)
			}
		}
		
		if ( [ (NSString*)processName isEqualToString: @"macfusionAgent"] )
		{
			runningAgentPath = processPath;
			runningAgentPID = processPID;
		}
			
		if ( [ (NSString*)processName isEqualToString: @"macfusionMenuling"] )
		{
			runningMenulingPath = processPath;
			runningMenulingPID = processPID;
		}

		CFRelease( processName );
	}
	
	if ( ( runningAgentPath == [NSNull null] || (runningAgentPath && ![runningAgentPath isEqualToString: mfcAgentBundlePath()]) )
		&& runningAgentPID != 0)
	{
		// Agent is in the trash or running from the wrong path. Kill it & restart it.
		MFLogS( self, @"Killing old or bad agent, and restarting." );
		kill( runningAgentPID, SIGKILL);
		mfcLaunchAgent();
	}
	
	if ( ( runningMenulingPath == [NSNull null] || (runningMenulingPath && ![runningMenulingPath isEqualToString: mfcMenulingBundlePath()]) )
		&& runningMenulingPID != 0)
	{
		// Menuling is in the trash or running from the wrong path. Kill it & restart it.
		MFLogS( self, @"Killing old or bad menuling, and restarting." );
		kill( runningMenulingPID, SIGKILL );
		mfcLaunchMenuling();
	}
}

# pragma mark Process Killing

// Kill all Macfusion Processes other than me
void mfcKaboomMacfusion()
{
	NSPredicate* macfusionAppsPredicate = [NSPredicate
										   predicateWithFormat: 
										   @"self.NSApplicationBundleIdentifier CONTAINS \
										   org.mgorbach.macfusion2 AND self.NSApplicationPath != %@", 
										   mfcMainBundlePath()];
	
	NSArray* macfusionApps = [[[NSWorkspace sharedWorkspace] launchedApplications] filteredArrayUsingPredicate:
							  macfusionAppsPredicate];
	NSArray* macfusionAppsPIDs = [macfusionApps valueForKey: @"NSApplicationProcessIdentifier"];
	for(NSNumber* pid in macfusionAppsPIDs)
	{
		kill( [pid intValue], SIGKILL );
	}
}

# pragma mark Trashing

void trashFSEventCallBack(ConstFSEventStreamRef streamRef, 
						  void *clientCallBackInfo, 
						  size_t numEvents, 
						  void *eventPaths, 
						  const FSEventStreamEventFlags eventFlags[], 
						  const FSEventStreamEventId eventIds[])
{
	if (![[NSFileManager defaultManager] fileExistsAtPath: mfcMainBundlePath()])
	{
		MFLogS(self, @"I have been deleted. Goodbye!");
		exit(0);
	}
}

void mfcSetupTrashMonitoring()
{
	FSEventStreamRef eventStream = FSEventStreamCreate( NULL, trashFSEventCallBack, NULL,
													   (CFArrayRef)[NSArray arrayWithObject: 
																	[mfcMainBundlePath() stringByDeletingLastPathComponent]],
													   kFSEventStreamEventIdSinceNow,
													   0, kFSEventStreamCreateFlagUseCFTypes );
	FSEventStreamScheduleWithRunLoop( eventStream,  [[NSRunLoop currentRunLoop] getCFRunLoop],
									 kCFRunLoopDefaultMode );
	FSEventStreamStart( eventStream );
}
