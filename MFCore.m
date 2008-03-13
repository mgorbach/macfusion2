//
//  MFCore.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/11/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFCore.h"
#define self @"MFCORE"

NSString* mainUIBundlePath()
{
	NSString* mainBundlePath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier: @"org.mgorbach.macfusion2"];
	return mainBundlePath;
}

NSString* menulingUIBundlePath()
{
	NSString* mainBundlePath = mainUIBundlePath();
	return [mainBundlePath stringByAppendingPathComponent:@"/Contents/Resources/MacfusionMenuling.app"];
}

NSArray* secretClientsForFileystem( MFFilesystem* fs )
{
	NSMutableArray* clientList = [NSMutableArray array];
	if ([[fs delegate] respondsToSelector:@selector(secretsClientsList)])
	{
		NSArray* fsList = [[fs delegate] secretsClientsList];
		if (fsList)
			[clientList addObjectsFromArray: fsList];
	}
	
	NSBundle* mainUIBundle = [NSBundle bundleWithPath: mainUIBundlePath()];
	[clientList addObject: [mainUIBundle executablePath]];
	NSBundle* menulingUIBundle = [NSBundle bundleWithPath: menulingUIBundlePath()];
	[clientList addObject: [menulingUIBundle executablePath]];
	// MFLogS(self, @"Client list for fs %@ is %@", fs, clientList);
	return [clientList copy];
}

BOOL getStateOfLoginItemWithPath( NSString* path )
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
		if (present)
			break;
	}
	
	CFRelease(loginItemsRef);
	return present;
}

BOOL getStateForAgentLoginItem()
{
	NSString* mainBundlePath = mainUIBundlePath();
	NSBundle* bundle = [NSBundle bundleWithPath: mainBundlePath];
	NSString* agentPath = [bundle pathForResource:@"macfusionAgent" ofType:nil];
	return getStateOfLoginItemWithPath( agentPath );
}

BOOL getStateForMenulingLoginItem()
{
	NSString* menulingBundlePath = menulingUIBundlePath();
	return getStateOfLoginItemWithPath(menulingBundlePath);
}

# pragma mark TODO: Unify these two functions
BOOL setStateForAgentLoginItem(BOOL state)
{
	NSString* mainBundlePath = mainUIBundlePath();
	NSBundle* bundle = [NSBundle bundleWithPath: mainBundlePath];
	NSString* agentPath = [bundle pathForResource:@"macfusionAgent" ofType:nil];
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (getStateOfLoginItemWithPath(agentPath) == state)
		return NO;
	
	UInt32 seedValue;
	NSArray  *loginItems = (NSArray *)LSSharedFileListCopySnapshot(loginItemsRef, &seedValue);
	for(id loginItem in loginItems)
	{
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)loginItem;
		NSURL* theURL = [NSURL new];
		LSSharedFileListItemResolve(itemRef, 0, (CFURLRef*)&theURL, NULL);
		NSString* checkPath = [[theURL path] lastPathComponent];
		if ([checkPath isEqualToString: @"macfusionAgent"])
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



BOOL setStateForMenulingLoginItem(BOOL state)
{
	NSString* menulingBundlePath = menulingUIBundlePath();
	LSSharedFileListRef loginItemsRef = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (getStateOfLoginItemWithPath(menulingBundlePath) == state)
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

NSString* getMacFuseVersion()
{
	NSDictionary* fuseData = [NSDictionary dictionaryWithContentsOfFile: 
							  @"/Library/Filesystems/fusefs.fs/Contents/Info.plist"];
	return [fuseData objectForKey: @"CFBundleVersion"];
}