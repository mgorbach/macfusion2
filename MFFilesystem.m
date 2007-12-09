//
//  MFFilesystem.m
//  macfusiond
//
//  Created by Michael Gorbach on 11/5/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import "MFFilesystem.h"
//#import "MFPluginController.h"
#import "MFPlugin.h"
#import "MFConstants.h"

@interface MFFilesystem(PrivateAPI)

@end

@implementation MFFilesystem

+ (MFFilesystem*)filesystemFromParameters:(NSDictionary*)parameters plugin:(MFPlugin*)p
{
//	MFFilesystem* fs = [[MFFilesystem alloc] initWithParameters: parameters plugin: p];
	MFFilesystem* fs = nil;
	NSBundle* b = p.bundle;
	NSString* filesystemClassName = [b objectForInfoDictionaryKey:@"MFFilesystemClass"];
	if (filesystemClassName == nil || [filesystemClassName isEqualToString:@"MFFilesystem"])
	{
		fs = [[MFFilesystem alloc] initWithParameters: parameters plugin: p];
	}
	else
	{
		BOOL success = [b load];
		if (success)
		{
			Class filesystemClass = NSClassFromString(filesystemClassName);
			fs = [[filesystemClass alloc] initWithParameters: parameters plugin:p];
		}
		else
		{
			MFLogS(self, @"Failed to load bundle for filesystem, bundle path %@", [b bundlePath]);
		}
	}
	
	return fs;
}

- (void)registerGeneralNotifications
{
	NSDistributedNotificationCenter* dnc = [NSDistributedNotificationCenter defaultCenter];
	[self addObserver:self
		   forKeyPath:@"status"
			  options:NSKeyValueObservingOptionOld || NSKeyValueObservingOptionNew
			  context:nil];
	
	[dnc addObserver:self
			selector:@selector(handleMountNotification:)
				name:@"mounted" 
			  object:@"com.google.filesystems.fusefs.unotifications"];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
														   selector:@selector(handleUnmountNotification:)
															   name:NSWorkspaceDidUnmountNotification 
															 object:nil];
}

- (MFFilesystem*)initWithParameters:(NSDictionary*)params plugin:(MFPlugin*)p
{
	self = [super init];
	plugin = p;
	parameters = [self fullParametersWithDictionary: params];
	self.status = kMFStatusFSUnmounted;
	[self registerGeneralNotifications];
	return self;
}

# pragma mark Parameter processing
- (NSMutableDictionary*)fullParametersWithDictionary:(NSDictionary*)fsParams
{
	NSDictionary* defaultParams = [plugin defaultParameterDictionary];
	NSMutableDictionary* params = [NSMutableDictionary dictionary];
	
	for(NSString* parameterKey in [defaultParams keyEnumerator])
	{
		id value;
		if ((value = [fsParams objectForKey:parameterKey]) != nil)
		{
			// The fs specifies a value for this parameter, take it.
			// Validation per-value goes here
			if (! [self validateValue: value forParameterNamed:parameterKey] )
			{
				MFLogS(self, "Parameter validation failed for parameter %@, plugin %@",
					  parameterKey);
			}
			[params setObject: [fsParams objectForKey:parameterKey]
					   forKey: parameterKey];
		}
		else 
		{
			// The fs doesn't specify a value for this parameter.
			// Use the default
			[params setObject: [defaultParams objectForKey:parameterKey]
					   forKey: parameterKey];
		}
			
	}
	
	return params;
}

- (BOOL)validateValue:(id)value forParameterNamed:(NSString*)param
{
	return YES;
}

# pragma mark Initialization


# pragma mark Task Creation methods
- (NSDictionary*)taskEnvironment
{
	// No modifications here
	return [[NSProcessInfo processInfo] environment];
}

- (NSArray*)taskArguments
{
					  
	// Default implementation will try to construct an argument list based
	// on the options dictionary and input format string
	NSMutableString* formatString = [[[self plugin] inputFormatString] mutableCopy];
	NSArray* argParameters;
	NSString* token;
	
	for(NSString* parameterKey in parameters)
	{
		// Filter for only those parameters that have tokens in the input format string
		if ((token = [[self plugin] tokenForParameter: parameterKey]) != nil)
		{
			// Place the token into place
			// TODO: SECURITY: Watch for instances of tokens in user input
			// TODO: Value typing
			NSString* searchString = [NSString stringWithFormat:@"[%@]", token];
			id value = [parameters objectForKey:parameterKey];
			NSString* stringValue;
			if ([value isKindOfClass: [NSString class]])
			{
				stringValue = value;
			}
			if ([value isKindOfClass: [NSNumber class]])
			{
				stringValue = [(NSNumber*)value stringValue];
			}
			
			[formatString replaceOccurrencesOfString:searchString 
										  withString:value 
											 options:NSLiteralSearch
											   range:NSMakeRange(0, [formatString length])];
		}
		
		// TODO: Handle options here
		// TODO: Handle environment here
			
	}
	
	argParameters = [formatString componentsSeparatedByString:@" "];
	return argParameters;
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
	NSString* launchPath = [[self plugin] taskPath];
	[t setLaunchPath: launchPath];
	
	[self setupIOForTask:t];
	[self registerNotificationsForTask:t];
	return t;
}
					

# pragma mark Mounting mechanics
- (BOOL)setupMountPoint
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* mountPath = [[self parameterDictionary] objectForKey:@"Mount Point"];
	BOOL pathExists, isDir;
	
	pathExists = [fm fileExistsAtPath:mountPath isDirectory:&isDir];
	if (pathExists && isDir == YES) // directory already exists
	{
		BOOL empty = ( [[fm directoryContentsAtPath:mountPath] count] == 0 );
		BOOL writeable = [fm isWritableFileAtPath:mountPath];
		if (!empty)
		{
			MFLogS(self, @"Mount point directory in use: %@", mountPath);
			return NO;
		}
		else if (!writeable)
		{
			MFLogS(self, @"Mount point directory not writeable: %@", mountPath);
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
	NSString* mountPath = [[self parameterDictionary] objectForKey:@"Mount Path"];
	BOOL pathExists, isDir;
	
	pathExists = [fm fileExistsAtPath:mountPath isDirectory:&isDir];
	if (pathExists && isDir && ([[fm directoryContentsAtPath:mountPath] count] == 0))
	{
		[fm removeFileAtPath:mountPath handler:nil];
	}
}

- (void)mount
{
	MFLogS(self, @"Mounting!");
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

# pragma mark Notification handlers
- (void)handleMountNotification:(NSNotification*)note
{
	NSDictionary* info = [note userInfo];
	if ([[info objectForKey:@"kFUSEMountPath"] 
		 isEqualToString:[parameters objectForKey:@"Mount Path"]])
	{
		// BINGO!
		self.status = kMFStatusFSMounted;
	}
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
		recentOutput = [[NSString alloc] initWithData: pipeData encoding:NSUTF8StringEncoding];
		[[note object] waitForDataInBackgroundAndNotify];
		MFLogS(self, recentOutput);
	}
}

- (void)handleUnmountNotification:(NSNotification*)note
{
	NSString* path = [[note userInfo] objectForKey:@"NSDevicePath"];
	NSString* mountPath = [parameters objectForKey:@"Mount Path"];
	if ([path isEqualToString:mountPath])
	{
		self.status = kMFStatusFSUnmounted;
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	MFLogS(self, @"Value change on %@", keyPath);
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

- (void)handleMountTimeout:(NSTimer*)timer
{
//	MFLogS(self, @"Mount timeout");
	if (self.status != kMFStatusFSUnmounted)
		self.status = kMFStatusFSFailed;
}

# pragma mark Accessors

- (NSString*)pluginID
{
	return [parameters objectForKey:@"Type"];
}

- (NSDictionary*)parameterDictionary
{
	// We want an immutable dictionary
	return [parameters copy];
}

- (id)valueForUndefinedKey:(NSString*)key
{
	id value = [parameters valueForKey:key];
	if (value)
	{
		return value;
	}
	
	return [super valueForUndefinedKey:key];
}

// TODO: Finalizer

@synthesize status, plugin;
@end
