//
//  MFClientFS.m
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

#import "MFClientFS.h"
#import "MFConstants.h"
#import "MFClientPlugin.h"
#import "MFServerFSProtocol.h"
#import "MFSecurity.h"

@interface MFClientFS (PrivateAPI)
- (void)fillInitialData;
- (void)registerNotifications;
- (void)copyParameters;
- (void)copyStatusInfo;
- (void)sendNotification:(NSString*)name;
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
		[remoteFS setProtocolForProxy:@protocol(MFServerFSProtocol)];
		plugin = p;
		delegate = [plugin delegate];
		[self fillInitialData];
		[self registerNotifications];
		displayOrder = 9999;
		[self updateSecrets];
	}
	
	return self;
}


- (void)registerNotifications
{
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
	
	if ([self isFailedToMount])
		[self performSelector:@selector(sendNotification:)
				   withObject:kMFClientFSFailedNotification
				   afterDelay:0];
}

#pragma mark Notifications To Clients
- (void)sendNotification:(NSString*)name

{
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:name
					  object:self
					userInfo:nil];
	if (clientFSDelegate && [clientFSDelegate respondsToSelector:@selector(filesystemDidChangeStatus:)])
		[clientFSDelegate filesystemDidChangeStatus:self];
}

- (void)sendNotificationForStatusChangeFrom:(NSString*)previousStatus
										 to:(NSString*)newStatus
{
	// MFLogS(self, @"Notifying for status %@ -> %@", previousStatus, newStatus);
	if ([previousStatus isEqualToString: newStatus])
	{
		// Send No Notification
	}
	
	if ([previousStatus isEqualToString: kMFStatusFSWaiting]
		&& [newStatus isEqualToString: kMFStatusFSMounted])
	{
		[self sendNotification: kMFClientFSMountedNotification];
	}
		
	else if ([previousStatus isEqualToString: kMFStatusFSWaiting]
			 && [newStatus isEqualToString: kMFStatusFSFailed])
	{
		[self sendNotification: kMFClientFSFailedNotification];
	}
		
}

#pragma mark Synchronization across IPC
- (void)handleStatusInfoChangedNotification:(NSNotification*)note
{
//	MFLogS(self, @"Handling notification %@", note);
	NSString* previousStatus = self.status;
	[self copyStatusInfo];
	// Hack this to synchronize the notifications and do
	[statusInfo setObject: [[note userInfo] objectForKey: kMFSTStatusKey]
				   forKey: kMFSTStatusKey];
	[self sendNotificationForStatusChangeFrom:previousStatus
										   to:[[note userInfo] objectForKey:kMFSTStatusKey]];
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
	backupSecrets = [NSDictionary dictionaryWithDictionary: secrets];
}

- (NSError*)endEditingAndCommitChanges:(BOOL)commit
{
	if (!isEditing)
	{
		[[NSException exceptionWithName:kMFBadAPIUsageException
								 reason:@"Calling endEditing without previous call to beginEditing"
							   userInfo:nil] raise];
	}
	
	if (commit)
	{
		NSError* result = [remoteFilesystem validateAndSetParameters: parameters];
		if (result)
		{
			// Validation failed
			return result;
		}
		else
		{
			// Update secure information
			if (![secrets isEqualToDictionary: backupSecrets])
			{
				mfsecSetSecretsDictionaryForFilesystem( secrets, self );
			}
			isEditing = NO;
			return nil;
		}
	}
	else
	{
		isEditing = NO;
		[self setParameters: [backupParameters mutableCopy] ];
		[self setSecrets: [backupSecrets mutableCopy]];

	}
	
	return nil;
}

- (NSImage*)iconImage
{
	return [[NSImage alloc] initWithContentsOfFile: 
			self.iconPath];
}

- (void)setPauseTimeout:(BOOL)p
{
	[remoteFilesystem setPauseTimeout: p];
}

# pragma mark UI
- (NSDictionary*)configurationViewControllers
{
	NSMutableDictionary* myControllers = [NSMutableDictionary dictionary];
	NSViewController* macfusionAdvancedController = [[NSViewController alloc] initWithNibName: @"macfusionAdvancedView"
																					   bundle: [NSBundle bundleForClass: [self class]]];
	[myControllers setObject: macfusionAdvancedController forKey:kMFUIMacfusionAdvancedViewKey];
	NSDictionary* delegateControllers = [delegate configurationViewControllers];
	if (!delegateControllers)
	{
		MFLogS(self, @"No view controllers specified by delegate");
	}
	
	[myControllers addEntriesFromDictionary: delegateControllers];
	return [myControllers copy];
}

@synthesize displayOrder, clientFSDelegate;
@end
