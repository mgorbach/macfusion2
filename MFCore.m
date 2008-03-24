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
	
	// MFLogS(self, @"Returning %@ for main bundle path", pathToReturn);
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
	// MFLogS(self, @"Client list for fs %@ is %@", fs, clientList);
	return [clientList copy];
}

BOOL mfcGetStateOfLoginItemWithPath( NSString* path )
{
	// MFLogS(self, @"Querying for %@", path);
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
		// MFLogS(self, @"Found %@", [theURL path]);
		if (present)
			break;
	}
	
	// MFLogS(self, @"Returning state %d for %@", present, path);
	CFRelease(loginItemsRef);
	return present;
}

BOOL mfcGetStateForAgentLoginItem()
{
	NSString* agentPath  = mfcAgentBundlePath();
	return mfcGetStateOfLoginItemWithPath( agentPath );
}

BOOL mfcGetStateForMenulingLoginItem()
{
	NSString* menulingBundlePath = mfcMenulingBundlePath();
	return mfcGetStateOfLoginItemWithPath(menulingBundlePath);
}

# pragma mark TODO: Unify these two functions
BOOL mfcSetStateForAgentLoginItem(BOOL state)
{
	NSString* agentPath = mfcAgentBundlePath();
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	// MFLogS(self, @"agentBundlePath set %@", agentPath);
	
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
			// MFLogS(self, @"Removing %@", theURL);
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



BOOL mfcSetStateForMenulingLoginItem(BOOL state)
{
	NSString* menulingBundlePath = mfcMenulingBundlePath();
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (mfcGetStateOfLoginItemWithPath(menulingBundlePath) == state)
		return NO;
	
	UInt32 seedValue;
	NSArray  *loginItems = (NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, &seedValue);
	for(id loginItem in loginItems)
	{
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)loginItem;
		NSURL* theURL = [NSURL new];
		LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*)&theURL, NULL);
		NSString* checkPath = [[theURL path] lastPathComponent];
		if ([checkPath isEqualToString: @"MacfusionMenuling.app"])
		{
			// MFLogS(self, @"Removing %@", theURL);
			LSSharedFileListItemRemove(loginItemsRef, itemRef);
		}
	}
	
	if(state == YES)
	{
		LSSharedFileListInsertItemURL(loginItemsRef, kLSSharedFileListItemLast, NULL, NULL, 
									  (CFURLRef)[NSURL fileURLWithPath: menulingBundlePath], NULL, NULL);
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