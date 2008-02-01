//
//  MFServerFS.m
//  MacFusion2
//
//  Created by Michael Gorbach on 1/12/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import "MFServerFS.h"
#import "MFConstants.h"
#import "MFPluginController.h"

@interface MFServerFS (PrivateAPI)
- (NSMutableDictionary*)fullParametersWithDictionary:(NSDictionary*)fsParams;
- (void)registerGeneralNotifications;
- (NSMutableDictionary*)initializedStatusInfo;
@end

@implementation MFServerFS
+ (MFServerFS*)filesystemFromParameters:(NSDictionary*)parameters 
								 plugin:(MFServerPlugin*)plugin
{

	/*
	NSString* filesystemClassName = [bundle objectForInfoDictionaryKey:@"MFServerFSClassName"];
	if (filesystemClassName == nil)
	{
		MFLogS(self, @"Failed to instantiate filesystem with parameters %@. No Server Filesystem class specified.",
			   parameters);
	}
	else
	{
		BOOL success = [bundle load];
		if (success)
		{
			Class filesystemClass = NSClassFromString(filesystemClassName);
			if ([filesystemClass isSubclassOfClass: [MFServerFS class]])
			{
				fs = [[filesystemClass alloc] initWithParameters: parameters Plugin: plugin];
			}
			else
			{
				MFLogS(self, @"Server Filesystem class %@ is not a subclass of MFServerFS",
					   filesystemClass);
			}
				
		}
		else
		{
			MFLogS(self, @"Failed to load bundle for filesystem, bundle path %@", 
				   [bundle bundlePath]);
		}
	}
	 */
	
	/*
	NSString* fsDelegateClassName = [bundle objectForInfoDictionaryKey:@"MFFSDelegateClassName"];
	if (fsDelegateClassName == nil)
	{
		MFLogS(self, @"Failed to instantiate filesystem with bundle path %@. No delegate class name specified.",
			   [bundle bundlePath]);
	}
	else 
	{
		BOOL success = [bundle load];
		if (success)
		{
			Class fsDelegateClass = NSClassFromString(filesystemClassName);
			
		}
	}
	 */
	
	return [[MFServerFS alloc] initWithParameters: parameters
										   plugin: plugin];
	
}

- (MFServerFS*)initWithParameters:(NSDictionary*)params 
						   plugin:(MFServerPlugin*)p
{
	if (self = [super init])
	{
		[self setPlugin: p];
		delegate = [p delegate];
		parameters = [self fullParametersWithDictionary: params];
		statusInfo = [self initializedStatusInfo];
		[self registerGeneralNotifications];
	}
	return self;
}

- (void)registerGeneralNotifications
{
	[self addObserver:self
		   forKeyPath:@"status"
			  options:NSKeyValueObservingOptionOld || NSKeyValueObservingOptionNew
			  context:nil];
	
	/*
	 [dnc addObserver:self
	 selector:@selector(handleMountNotification:)
	 name:@"mounted" 
	 object:@"com.google.filesystems.fusefs.unotifications"];
	 [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
	 selector:@selector(handleUnmountNotification:)
	 name:NSWorkspaceDidUnmountNotification 
	 object:nil];
	 */
}

- (NSMutableDictionary*)initializedStatusInfo
{
	NSMutableDictionary* initialStatusInfo = [NSMutableDictionary dictionaryWithCapacity:5];
	// Initialize the important keys in the status dictionary
	[initialStatusInfo setObject:kMFStatusFSUnmounted
						  forKey:@"status"];
	[initialStatusInfo setObject:@"None"
						  forKey:@"faliureReason"];
	[initialStatusInfo setObject:[NSMutableString stringWithString:@""]
						  forKey:@"output"];
	
	// get A UUID to identify this filesystem by
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString* uuid = [(NSString *)string autorelease];
	[initialStatusInfo setObject:uuid
						  forKey:@"uuid"];
	return initialStatusInfo;
}



# pragma mark Parameter processing
- (NSMutableDictionary*)fullParametersWithDictionary:(NSDictionary*)fsParams
{
	NSDictionary* defaultParams = [delegate defaultParameterDictionary];
	NSMutableDictionary* params = [fsParams mutableCopy];
	if(!params)
	{
		params = [NSMutableDictionary dictionary];
	}
	
	for(NSString* parameterKey in [defaultParams keyEnumerator])
	{
		id value;
		if ((value = [fsParams objectForKey:parameterKey]) != nil)
		{
			/*
			MFLogS(self, @"Validated value %@ for parameter %@",
				   [fsParams objectForKey: parameterKey],
				   parameterKey);
			 */
		}
		else 
		{
			/*
			// The fs doesn't specify a value for this parameter.
			// Use the default
			[params setObject: [defaultParams objectForKey:parameterKey]
					   forKey: parameterKey];
			MFLogS(self, @"Using default value for parameter %@",
				   parameterKey);
			 */
		}
		
	}
	
	return params;
}

# pragma mark Initialization

# pragma mark Task Creation methods
- (NSDictionary*)taskEnvironment
{
	if ([delegate respondsToSelector:@selector(taskEnvironmentForParameters:)])
		return [delegate taskEnvironmentForParameters: parameters];
	else
		return [[NSProcessInfo processInfo] environment];
}

- (NSArray*)taskArguments
{
	if ([delegate respondsToSelector:@selector(taskArgumentsForParameters:)])
	{
		return [delegate taskArgumentsForParameters: parameters];
	}
	else
	{
		MFLogS(self, @"Could not get task arguments for delegate!");
		return nil;
	}
}

- (void)setupIOForTask:(NSTask*)t
{
	NSPipe* outputPipe = [[NSPipe alloc] init];
	NSPipe* inputPipe = [[NSPipe alloc] init];
	[t setStandardError: outputPipe];
	[t setStandardOutput: outputPipe];
	[t setStandardInput: inputPipe];
}

- (void)registerNotificationsForTask:(NSTask*)t
{
	NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(handleDataOnPipe:)
			   name:NSFileHandleDataAvailableNotification 
			 object:[[t standardOutput] fileHandleForReading]];
	[nc addObserver:self
		   selector:@selector(handleTaskDidTerminate:) 
			   name:NSTaskDidTerminateNotification
			 object:t];
}

- (NSTask*)taskForLaunch
{
	NSTask* t = [[NSTask alloc] init];
	
	// Pull together all the tasks parameters
	NSDictionary* env = [self taskEnvironment];
	[t setEnvironment: env];
	NSArray* args = [self taskArguments];
	[t setArguments: args];
	NSString* launchPath = [delegate executablePath];
	[t setLaunchPath: launchPath];
	
	[self setupIOForTask:t];
	[self registerNotificationsForTask:t];
	return t;
}


# pragma mark Mounting mechanics
- (BOOL)setupMountPoint
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* mountPath = [self mountPath];
	BOOL pathExists, isDir;
	
	pathExists = [fm fileExistsAtPath:mountPath isDirectory:&isDir];
	if (pathExists && isDir == YES) // directory already exists
	{
		BOOL empty = ( [[fm directoryContentsAtPath:mountPath] count] == 0 );
		BOOL writeable = [fm isWritableFileAtPath:mountPath];
		if (!empty)
		{
			MFLogS(self, @"Mount path directory in use: %@", mountPath);
			return NO;
		}
		else if (!writeable)
		{
			MFLogS(self, @"Mount path directory not writeable: %@", mountPath);
			return NO;
		}
		else
		{
			// Mount point exists and is useable. We're all good.
			return YES;
		}
	}
	else if (pathExists && !isDir)
	{
		MFLogS(self, @"Mount point path is a file, not a directory: %@", mountPath);
		return NO;
	}
	else if (!pathExists)
	{
		MFLogS(self, @"Creating directory %@", mountPath);
		[fm createDirectoryAtPath:mountPath attributes:nil];
		return YES;
	}
	
	return NO;
}

- (void)removeMountPoint
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* mountPath = [[self parameters] objectForKey:@"Mount Path"];
	BOOL pathExists, isDir;
	
	pathExists = [fm fileExistsAtPath:mountPath isDirectory:&isDir];
	if (pathExists && isDir && ([[fm directoryContentsAtPath:mountPath] count] == 0))
	{
		[fm removeFileAtPath:mountPath handler:nil];
	}
}

- (void)mount
{
	if (self.status == kMFStatusFSMounted)
	{
		return;
	}
	
	MFLogS(self, @"Mounting");
	self.status = kMFStatusFSWaiting;
	if ([self setupMountPoint] == YES)
	{
		task = [self taskForLaunch];
		[[[task standardOutput] fileHandleForReading]
		 waitForDataInBackgroundAndNotify];
		
		[NSTimer scheduledTimerWithTimeInterval:5.0 
										 target:self
									   selector:@selector(handleMountTimeout:)
									   userInfo:nil 
										repeats:NO];
		
		[task launch];
		MFLogS(self, @"Task launched OK");
	}
	else
	{
		MFLogS(self, @"Mount point could not be created");
		self.status = kMFStatusFSFailed;
	}
}

- (void)unmount
{
	MFLogS(self, @"Unmounting");
	NSString* path = [[self mountPath] stringByStandardizingPath];
	NSString* taskPath = @"/sbin/umount";
	NSTask* t = [[NSTask alloc] init];
	[t setLaunchPath: taskPath];
	[t setArguments: [NSArray arrayWithObject: path]];
	[t launch];
	[t waitUntilExit];
	if ([t terminationStatus] != 0)
	{
		MFLogS(self, @"Unmount failed. Unmount terminates with %d",
		[t terminationStatus]);
	}
}

# pragma mark Validation
- (NSString*)validateAndSetParameters:(NSDictionary*)params
{
	// For subclassing
	
	[self willChangeValueForKey:@"parameters"];
	parameters = [params mutableCopy];
	[self didChangeValueForKey:@"parameters"];
	return nil;
}

# pragma mark Notification handlers
- (void)handleMountNotification
{
	MFLogS(self, @"Mount notification received");
	self.status = kMFStatusFSMounted;
}

- (void)handleTaskDidTerminate:(NSNotification*)note
{
	MFLogS(self, @"Task terminated");
	if (self.status == kMFStatusFSMounted)
	{
		// We are terminating after a mount has been successful
		// This may not quite be normal (may be for example a bad net connection)
		// But we'll set status to unmounted anyway
		self.status = kMFStatusFSUnmounted;
	}
	else if (self.status == kMFStatusFSWaiting)
	{
		// We terminated while trying to mount
		self.status = kMFStatusFSFailed;
	}
}

- (void)appendToOutput:(NSString*)newOutput
{
	NSMutableString* output = [statusInfo objectForKey:@"output"];
	[output appendString: newOutput];
}

- (void)handleDataOnPipe:(NSNotification*)note
{
	NSData* pipeData = [[note object] availableData];
	if ([pipeData length] == 0)
	{
		// pipe is now closed
		return;
	}
	else
	{
		NSString* recentOutput = [[NSString alloc] 
								  initWithData: pipeData
								  encoding:NSUTF8StringEncoding];
		
		[self appendToOutput: recentOutput];
		[[note object] waitForDataInBackgroundAndNotify];
		MFLogS(self, recentOutput);
	}
}

- (void)handleUnmountNotification
{
	self.status = kMFStatusFSUnmounted;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	MFLogS(self, @"Value change on %@ to %@", keyPath, [change objectForKey: NSKeyValueChangeNewKey]);
	if ([keyPath isEqualToString:@"status"] &&
		object == self && 
		[change objectForKey:NSKeyValueChangeNewKey] == kMFStatusFSUnmounted)
	{
		[self removeMountPoint];
	}
	
	/*
	 [super observeValueForKeyPath:keyPath
	 ofObject:object
	 change:change
	 context:context];
	 */
}

- (NSMutableDictionary*)parameters
{
	return parameters;
}


- (void)handleMountTimeout:(NSTimer*)timer
{
	if (self.status != kMFStatusFSUnmounted && self.status != kMFStatusFSMounted)
		self.status = kMFStatusFSFailed;
}

@synthesize plugin;
@end
