//
//  MFCommunicationServer.m
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

#import "MFCommunicationServer.h"
#import "MFFilesystemController.h"
#import "MFFilesystem.h"
#import "MFPluginController.h"
#import "MFConstants.h"
#import "MFPreferences.h"
#import "MFClientProtocol.h"
#import "MFLogging.h"

@implementation MFCommunicationServer
static MFCommunicationServer *sharedServer = nil;


+ (MFCommunicationServer *)sharedServer {
	if (sharedServer == nil) {
		sharedServer = [[self alloc] init];
	}
	
	return sharedServer;
}

- (void)registerNotifications {
	NSArray *filesystems = [[self filesystemController] filesystems];
	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [filesystems count])];
	[filesystems addObserver:self toObjectsAtIndexes:indexes forKeyPath:@"status" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	[filesystems addObserver:self toObjectsAtIndexes:indexes forKeyPath:@"parameters" options:NSKeyValueObservingOptionNew context:nil];
	
	[[MFFilesystemController sharedController] addObserver:self forKeyPath:@"filesystems" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	[[MFFilesystemController sharedController] addObserver:self forKeyPath:@"plugins" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	[[MFFilesystemController sharedController] addObserver:self forKeyPath:@"recents" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}

- (id) init {
	self = [super init];
	if (self != nil) {
		_clients = [NSMutableArray array];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleConnectionDidDie:) name:NSConnectionDidDieNotification object:nil];
	}
	
	return self;
}

- (void)vendDisributedObject {
	NSLog(@"Vending distribution object ... %@", self);
	NSConnection *connection = [NSConnection new];
	[connection setRootObject:self];
	if ([connection registerName:kMFDistributedObjectName] == YES) {
		NSLog(@"Connection registered!");
	} else {
		MFLogS(self, @"Failed to register connection name");
		exit(-1);
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"status"] && [object isKindOfClass:[MFFilesystem class]]
		&& ![[change objectForKey:NSKeyValueChangeOldKey] isEqualToString:[change objectForKey:NSKeyValueChangeNewKey]]) {
		MFFilesystem *fs = (MFFilesystem *)object;
		[_clients makeObjectsPerformSelector:@selector(noteStatusChangedForFSWithUUID:) withObject:fs.uuid];
	}
	
	if ([keyPath isEqualToString:@"parameters"] && [object isKindOfClass:[MFFilesystem class]]) {
		MFFilesystem *fs = (MFFilesystem*)object;
		[_clients makeObjectsPerformSelector:@selector(noteParametersChangedForFSWithUUID:) withObject:fs.uuid];
	}
	
	if ([keyPath isEqualToString:@"filesystems"] && object == [MFFilesystemController sharedController]) {
		NSUInteger changeKind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
		if(changeKind == NSKeyValueChangeInsertion) {
			for (MFServerFS *fs in [change objectForKey:NSKeyValueChangeNewKey]) {
				[fs addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
				[fs addObserver:self forKeyPath:@"parameters" options:NSKeyValueObservingOptionNew context:nil];
				[_clients makeObjectsPerformSelector:@selector(noteFilesystemAddedWithUUID:) withObject:[fs uuid]];
			}
		}
		
		if(changeKind == NSKeyValueChangeRemoval) {
			for(MFServerFS *fs in [change objectForKey:NSKeyValueChangeOldKey]) {
				[fs removeObserver:self forKeyPath:@"status"];
				[fs removeObserver:self forKeyPath:@"parameters"];
				[_clients makeObjectsPerformSelector:@selector(noteFilesystemRemovedWithUUID:) withObject:[fs uuid]];
			}
		}
	}
	
	if ([keyPath isEqualToString:@"recents"] && object == [MFFilesystemController sharedController]) {
		NSUInteger changeKind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
		if (changeKind == NSKeyValueChangeInsertion) {
			NSArray *newRecents = [change objectForKey:NSKeyValueChangeNewKey];
			for(NSDictionary *recentsDict in newRecents) {
				[_clients makeObjectsPerformSelector:@selector(noteRecentAdded:) withObject:recentsDict];
			 }
		}
	}
}

- (NSArray *)recents {
	return [[MFFilesystemController sharedController] recents];
}

- (MFFilesystemController *)filesystemController {
	return [MFFilesystemController sharedController];
}

- (MFPluginController *)pluginController {
	return [MFPluginController sharedController];
}

- (void)doInitializationComplete:(NSTimer *)timer {
	if ([[MFPreferences sharedPreferences] getBoolForPreference:kMFPrefsAutoloadMenuling]) {
		[[NSWorkspace sharedWorkspace] launchApplication:(NSString *)mfcMenulingBundlePath()];
	}
}

- (void)startServing {
	[[MFLogging sharedLogging] setDelegate:self];
	[self registerNotifications];
	[self vendDisributedObject];
	NSTimer *timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(doInitializationComplete:) userInfo:nil repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}


# pragma mark Action Methods
- (MFServerFS *)newFilesystemWithPluginName:(NSString *)pluginName {
	NSAssert(pluginName, @"MFCommunicationServer: Asked for new filesystem with nil plugin name");
	MFServerPlugin *plugin = [[[MFPluginController sharedController] pluginsDictionary] objectForKey:pluginName];
	NSAssert(plugin, @"MFCommunicationServer: Asked for FS with invalid plugin name");
	MFServerFS *fs = [[MFFilesystemController sharedController] newFilesystemWithPlugin:plugin];
	return fs;
}
				 
- (MFServerFS *)filesystemWithUUID:(NSString *)uuid {
	NSAssert(uuid, @"Filesystem requested with nil uuid in server");
	return [[MFFilesystemController sharedController] filesystemWithUUID:uuid];
}

- (MFServerFS *)quickMountWithURL:(NSURL *)url {
	NSError *error;
	MFServerFS *fs = [[MFFilesystemController sharedController] quickMountWithURL:url error:&error];
	if (error) {
		_recentError = error;
	}
	return fs;
}
				 
- (void)deleteFilesystemWithUUID:(NSString *)uuid {
	MFServerFS *fs = [[MFFilesystemController sharedController] filesystemWithUUID:uuid];
	NSAssert(fs, @"CommunicationServer asked to remove filesystem with bad uuid");
	[[MFFilesystemController sharedController] deleteFilesystem:fs];
}

#pragma mark Security Tokens
- (NSString *)tokenForFilesystemWithUUID:(NSString *)uuid {
	MFServerFS *fs = [[MFFilesystemController sharedController] filesystemWithUUID:uuid];
	return [[MFFilesystemController sharedController] tokenForFilesystem:fs];
}

- (MFServerFS *)filesystemForToken:(NSString *)token {
	MFServerFS *fs = [[MFFilesystemController sharedController] filesystemForToken:token];
	if (fs) {
		[[MFFilesystemController sharedController] invalidateToken:token];
	}
	return fs;
}

#pragma mark Sever Protocol Methods
- (NSArray *)filesystems {
	return [[MFFilesystemController sharedController] filesystems];
}

- (NSArray *)plugins {
	return [[MFPluginController sharedController] plugins];
}

- (NSError *)recentError {
	return _recentError;
}

#pragma mark Client Registration/UnRegistration
- (void)registerClient:(id <MFClientProtocol>) client {
	NSAssert([client conformsToProtocol:@protocol(MFClientProtocol)], @"Client doesn't conform to protocol, registerClient");
	[_clients addObject:client];
}

- (void)unregisterClient:(id <MFClientProtocol>) client {
	NSAssert([client conformsToProtocol:@protocol(MFClientProtocol)], @"Client doesn't conform to protocol, unregisterClient");
	NSAssert([_clients containsObject:client], @"Client not registered, unregisterClient");
	[_clients removeObject:client];
}

- (void)handleConnectionDidDie:(NSNotification *)note {
	// NSLog(@"Connection did die on server! %@ object %@ userInfo %@", note, [note object], [note userInfo]);
	for(id obj in _clients) {
		if ([obj connectionForProxy] == [note object]) {
			// NSLog(@"Killing %@", obj);
			[_clients removeObject:obj];
		}
	}
}

- (NSString *)agentBundlePath {
	return [[NSBundle mainBundle] bundlePath];
}

# pragma mark Logging
- (void)sendASLMessageDict:(NSDictionary *)messageDict {
	@try {
		[_clients makeObjectsPerformSelector:@selector(recordASLMessageDict:) withObject:messageDict];
	}
	@catch (NSException* e) {
		return;
	}
}

@end
