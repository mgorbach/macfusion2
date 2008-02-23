//
//  MFClientFS.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/5/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFClientFS.h"
#import "MFConstants.h"
#import "MFClientPlugin.h"

@interface MFClientFS (PrivateAPI)
- (void)fillInitialData;
- (void)registerNotifications;
- (void)copyParameters;
- (void)copyStatusInfo;
@end

@implementation MFClientFS

+ (MFClientFS*)clientFSWithRemoteFS:(id)remoteFS 
					   clientPlugin:(MFClientPlugin*)plugin
{
	MFClientFS* fs = nil;
	
	fs = [[MFClientFS alloc] initWithRemoteFS: remoteFS
								 clientPlugin: plugin];
	return fs;
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key
{
	if ([key isEqualToString: @"displayDictionary"])
		return [NSSet setWithObjects: 
				KMFStatusDict, kMFParameterDict, nil];
	else
		return [super keyPathsForValuesAffectingValueForKey: key];
}

- (id)initWithRemoteFS:(id)remoteFS 
		  clientPlugin:(MFClientPlugin*)p
{
	self = [super init];
	if (self != nil)
	{
		remoteFilesystem = remoteFS;
		plugin = p;
		delegate = [plugin delegate];
		[self fillInitialData];
		[self registerNotifications];
	}
	
	return self;
}


- (void)registerNotifications
{
	/*
	[self addObserver:self
		   forKeyPath:kMFParameterDict
			  options:NSKeyValueObservingOptionNew
			  context:nil];
	 */
}

- (void)copyStatusInfo
{
	[self willChangeValueForKey:KMFStatusDict];
	statusInfo = [[remoteFilesystem statusInfo] mutableCopy];
	NSAssert(![statusInfo isProxy], @"Status Info from DO is a Proxy. Oh shit.");
	[self didChangeValueForKey:KMFStatusDict];
}

- (void)copyParameters
{
	[self willChangeValueForKey:kMFParameterDict];
	parameters = [[remoteFilesystem parameters] mutableCopy];
	NSAssert(![parameters isProxy], @"Parameters from DO is a Proxy. Oh shit.");
	[self didChangeValueForKey:kMFParameterDict];
}

- (void)fillInitialData
{
	[self copyStatusInfo];
	[self copyParameters];
}

- (void)toggleMount:(id)sender
{
	[remoteFilesystem mount];
}

#pragma mark Synchronization across IPC
- (void)handleStatusInfoChangedNotification:(NSNotification*)note
{
	[self copyStatusInfo];
}

- (void)handleParametersChangedNotification:(NSNotification*)note
{
	[self copyParameters];
}

- (NSDictionary*)displayDictionary
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[dict addEntriesFromDictionary: parameters];
	[dict addEntriesFromDictionary: statusInfo];
	return [dict copy];
}

# pragma mark Action Methods
- (void)mount
{
	[remoteFilesystem mount];
}

- (void)unmount
{
	[remoteFilesystem unmount];
}


#pragma mark Editing

- (void)setParameters:(NSMutableDictionary*)p
{
	parameters = p;
}

- (void)beginEditing
{
	isEditing = YES;
	backupParameters = [NSDictionary dictionaryWithDictionary: 
						[self parameters]];
}

- (NSError*)endEditingAndCommitChanges:(BOOL)commit
{
	if (!isEditing)
	{
		[[NSException exceptionWithName:kMFBadAPIUsageException
								 reason:@"endEditing without beginEditing"
							   userInfo:nil] raise];
	}
	
	if (commit)
	{
		NSError* result = [remoteFilesystem validateAndSetParameters: parameters];
		if (result)
		{
			return result;
		}
		else
		{
			isEditing = NO;
			return nil;
		}
	}
	else
	{
		isEditing = NO;
		[self setParameters: [backupParameters mutableCopy] ];
	}
	
	return nil;
}

- (void)willChangeValueForKey:(NSString*)key
{
	if ([key isLike:@"parameters.*"] && !isEditing)
	{
		[[NSException exceptionWithName:@"MFBadAPIUsage"
								reason:@"Trying to modify parameters without beginEditing"
							  userInfo:nil] raise];
	}
	
	[super willChangeValueForKey:key];
}

@end
