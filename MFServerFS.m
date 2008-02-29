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
#import "MFError.h"

@interface MFServerFS (PrivateAPI)
- (MFServerFS*)initWithPlugin:(MFServerPlugin*)p;
- (MFServerFS*)initWithParameters:(NSDictionary*)params 
						   plugin:(MFServerPlugin*)p;

- (NSMutableDictionary*)fullParametersWithDictionary:(NSDictionary*)fsParams;
- (void)registerGeneralNotifications;
- (NSMutableDictionary*)initializedStatusInfo;
- (void)writeOutData;
- (NSString*)getNewUUID;
- (BOOL)validateParameters:(NSDictionary*)params
				 WithError:(NSError**)error;
@end

@implementation MFServerFS

+ (MFServerFS*)newFilesystemWithPlugin:(MFServerPlugin*)plugin
{
	if (plugin)
	{
		return [[self alloc] initWithPlugin: plugin];
	}
	
	return nil;
}

+ (MFServerFS*)loadFilesystemAtPath:(NSString*)path 
							  error:(NSError**)error
{
	MFServerFS* fs;
	NSMutableDictionary* fsParameters = [NSMutableDictionary dictionaryWithContentsOfFile: path];
	if (!fsParameters)
	{
		NSDictionary* errorDict = [NSDictionary dictionaryWithObjectsAndKeys: 
								   @"Could not read dictionary data for filesystem", NSLocalizedDescriptionKey,
								   [NSString stringWithFormat: @"File at path %@", path],
								   NSLocalizedRecoverySuggestionErrorKey, nil];
		*error = [NSError errorWithDomain: kMFErrorDomain
							code: kMFErrorCodeDataCannotBeRead
						userInfo: errorDict ];
		return nil;
	}
	
	[fsParameters setObject: path forKey:kMFFSFilePathParameter];
	[fsParameters setObject: [NSNumber numberWithBool:YES] forKey:kMFFSPersistentParameter ];
	
	NSString* pluginID = [fsParameters objectForKey: kMFFSTypeParameter];
	if (!pluginID)
	{
		NSDictionary* errorDict = [NSDictionary dictionaryWithObjectsAndKeys: 
								   @"Could not read plugin id key for filesystem", NSLocalizedDescriptionKey,
								   [NSString stringWithFormat: @"File at path %@", path],
								   NSLocalizedRecoverySuggestionErrorKey, nil];
		*error = [NSError errorWithDomain: kMFErrorDomain
									 code: kMFErrorCodeMissingParameter
								 userInfo: errorDict ];
		return nil;
	}
	
	MFServerPlugin* plugin = [[MFPluginController sharedController] 
							  pluginWithID:pluginID];
	if (plugin)
	{
		fs = [[MFServerFS alloc] initWithParameters: fsParameters
											 plugin: plugin ];
		NSError* validationError;
		BOOL ok = [fs validateParametersWithError: &validationError];
		if (ok)
		{
			return fs;
		}
		else
		{		   
			*error = validationError;
			return nil;
			
		}
	}
	else
	{
		NSDictionary* errorDict = [NSDictionary dictionaryWithObjectsAndKeys: 
								   @"Invalid plugin ID given", NSLocalizedDescriptionKey,
								   [NSString stringWithFormat: @"File at path %@", path],
								   NSLocalizedRecoverySuggestionErrorKey, nil];
		*error = [NSError errorWithDomain: kMFErrorDomain
									 code: kMFErrorCodeInvalidParameterValue
								 userInfo: errorDict ];
		return nil;
	}
}


+ (MFServerFS*)filesystemFromURL:(NSURL*)url
						  plugin:(MFServerPlugin*)p
						   error:(NSError**)error
{
	NSMutableDictionary* params = [[[p delegate] parameterDictionaryForURL: url 
																	 error: error] 
								   mutableCopy];
	if (!params) 
	{
		*error = [MFError errorWithErrorCode:kMFErrorCodeMountFaliure
								 description:@"Plugin failed to parse URL"];
		return nil;
	}
	[params setValue: [NSNumber numberWithBool: NO] 
			  forKey: kMFFSPersistentParameter ];
	[params setValue: p.ID
			  forKey: kMFFSTypeParameter ];
	[params setValue: [NSString stringWithFormat: @"%@", url]
			  forKey: kMFFSDescriptionParameter ];
	MFServerFS* fs = [[MFServerFS alloc] initWithParameters: params
													 plugin: p];
	NSError* validationError;
	BOOL ok = [fs validateParametersWithError: &validationError];
	if (!ok)
	{
		error = &validationError;
		return nil;
	}
	else
	{
		return fs;
	}
	
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
		if ( ![parameters objectForKey: KMFFSUUIDParameter] )
		{
			[parameters setObject: [self getNewUUID]
						   forKey: KMFFSUUIDParameter ];
		}
		
		[self registerGeneralNotifications];
	}
	return self;
}
		 
- (MFServerFS*)initWithPlugin:(MFServerPlugin*)p
{
	NSAssert(p, @"Plugin null in MFServerFS initWithPlugin");
	NSDictionary* newFSParameters = [NSDictionary dictionaryWithObjectsAndKeys: 
									 p.ID, kMFFSTypeParameter,
									 [NSNumber numberWithBool: YES], kMFFSPersistentParameter,
									 nil ];
									 
	return [self initWithParameters: newFSParameters plugin: p ];
}


- (void)registerGeneralNotifications
{
	[self addObserver:self
		   forKeyPath:KMFStatusDict
			  options:NSKeyValueObservingOptionOld || NSKeyValueObservingOptionNew
			  context:nil];
	[self addObserver:self
		   forKeyPath:kMFParameterDict
			  options:NSKeyValueObservingOptionOld || NSKeyValueObservingOptionNew
			  context:nil];
}

- (NSMutableDictionary*)initializedStatusInfo
{
	NSMutableDictionary* initialStatusInfo = [NSMutableDictionary dictionaryWithCapacity:5];
	// Initialize the important keys in the status dictionary
	[initialStatusInfo setObject:kMFStatusFSUnmounted
						  forKey: kMFSTStatusKey];
	[initialStatusInfo setObject:[NSMutableString stringWithString:@""]
						  forKey: kMFSTOutputKey ];
	return initialStatusInfo;
}

- (NSString*)getNewUUID
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString* uuid = [(NSString *)string autorelease];
	return uuid;
}


- (NSDictionary*)defaultParameterDictionary
{
	NSMutableDictionary* defaultParameterDictionary =[NSMutableDictionary dictionary];
	NSDictionary* delegateDict = [delegate defaultParameterDictionary];
	
	[defaultParameterDictionary addEntriesFromDictionary: delegateDict];
	
	return [defaultParameterDictionary copy];
}

# pragma mark Parameter processing
- (NSMutableDictionary*)fullParametersWithDictionary:(NSDictionary*)fsParams
{
	NSDictionary* defaultParams = [self defaultParameterDictionary];
	NSMutableDictionary* params = [fsParams mutableCopy];
	if(!params)
	{
		params = [NSMutableDictionary dictionary];
	}
	

	for(NSString* parameterKey in [defaultParams allKeys])
	{
		id value;
		if ((value = [fsParams objectForKey:parameterKey]) != nil)
		{
		}
		else 
		{
			[params setObject: [defaultParams objectForKey: parameterKey]
					   forKey: parameterKey];
		}
		
	}
	
	return params;
}

# pragma mark Initialization

# pragma mark Task Creation methods
- (NSDictionary*)taskEnvironment
{
	if ([delegate respondsToSelector:@selector(taskEnvironmentForParameters:)])
		return [delegate taskEnvironmentForParameters: [self parametersWithImpliedValues]];
	else
		return [[NSProcessInfo processInfo] environment];
}

- (NSArray*)taskArguments
{
	if ([delegate respondsToSelector:@selector(taskArgumentsForParameters:)])
	{
		return [delegate taskArgumentsForParameters: [self parametersWithImpliedValues]];
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
	BOOL pathExists, isDir, returnValue;
	NSString* errorDescription;
	
	NSAssert(mountPath, @"Attempted to filesystem with nil mountPath.");
		
	pathExists = [fm fileExistsAtPath:mountPath isDirectory:&isDir];
	if (pathExists && isDir == YES) // directory already exists
	{
		BOOL empty = ( [[fm directoryContentsAtPath:mountPath] count] == 0 );
		BOOL writeable = [fm isWritableFileAtPath:mountPath];
		if (!empty)
		{
			errorDescription = @"Mount path directory in use.";
			returnValue = NO;
		}
		else if (!writeable)
		{
			errorDescription = @"Mount path directory not writeable.";
			returnValue = NO;
		}
		else
		{
			returnValue = YES;
		}
	}
	else if (pathExists && !isDir)
	{
		errorDescription = @"Mount path is a file, not a directory.";
		returnValue = NO;
	}
	else if (!pathExists)
	{
		if ([fm createDirectoryAtPath:mountPath attributes:nil])
			returnValue = YES;
		else
		{
			errorDescription = @"Mount path could not be created.";
			returnValue = NO;
		}
	}
	
	if (returnValue == NO)
	{
		NSError* error = [MFError errorWithErrorCode:kMFErrorCodeMountFaliure
										 description:errorDescription];
		[statusInfo setObject: error forKey: kMFSTErrorKey ];
		return NO;
	}
	else
	{
		return YES;
	}
}

- (void)removeMountPoint
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* mountPath = [self mountPath];
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
- (NSError*)validateAndSetParameters:(NSDictionary*)params 
{
	NSError* error;
	if ([self validateParameters: params
					   WithError: &error])
	{
		[self willChangeValueForKey: kMFParameterDict];
		parameters = [params mutableCopy];
		[self didChangeValueForKey: kMFParameterDict];
	}
	else
	{
		return error;
	}
	
	return nil;
}

- (BOOL)validateParameters:(NSDictionary*)params
				 WithError:(NSError**)error
{
	NSDictionary* impliedParams = [self fillParametersWithImpliedValues: params];
	BOOL ok = [delegate validateParameters: impliedParams
									 error: error];
	if (!ok) // Delegate didn't validate
	{
		// MFLogS(self, @"Delegate didn't validate %@", impliedParams);
		return NO;
	}
	else
	{
		// MFLogS(self, @"Delegate did validate %@", impliedParams);
		// Continue validation for general macfusion keys
		if (![impliedParams objectForKey: kMFFSVolumeNameParameter])
		{
			*error = [MFError parameterMissingErrorWithParameterName: kMFFSVolumeNameParameter];
			return NO;
		}
		if (![impliedParams objectForKey: kMFFSMountPathParameter])
		{
			*error = [MFError parameterMissingErrorWithParameterName: kMFFSMountPathParameter];
			return NO;
		}
		if (![impliedParams objectForKey: KMFFSUUIDParameter])
		{
			*error = [MFError parameterMissingErrorWithParameterName: KMFFSUUIDParameter];
			return NO;
		}
	}
	
	return YES;
}

- (BOOL)validateParametersWithError:(NSError**)error
{
	return [self validateParameters: parameters WithError: error];
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
	NSMutableString* output = [statusInfo objectForKey: kMFSTOutputKey];
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
	if ([keyPath isEqualToString: KMFStatusDict ] &&
		object == self && 
		[change objectForKey:NSKeyValueChangeNewKey] == kMFStatusFSUnmounted)
	{
		[self removeMountPoint];
	}
	
	if ([keyPath isEqualToString: kMFParameterDict])
	{
		[self writeOutData];
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
	if (![self isUnmounted] && ![self isMounted])
		if (![self isFailedToMount])
			self.status = kMFStatusFSFailed;
}

# pragma mark Write out
- (void)writeOutData
{
	if  ([self isPersistent])
	{
		NSString* dirPath = [@"~/Library/Application Support/Macfusion/Filesystems"
							 stringByExpandingTildeInPath];
		
		BOOL isDir;
		if (![[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&isDir] || !isDir) 
		{
			NSError* error = nil;
			BOOL ok = [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
												withIntermediateDirectories:YES
																 attributes:nil error:&error];
			if (!ok)
			{
				MFLogS(self, @"Failed to create directory save filesystem %@", 
					   [error localizedDescription]);
			}
			
		}
		
		NSString* path = [self valueForParameterNamed: kMFFSFilePathParameter ];
		[parameters writeToFile: [dirPath stringByAppendingFormat: @"/%@.macfusion", path]
					 atomically: YES];
	}
}

- (NSError*)errorForFaliure
{
	NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys: 
								self.uuid, kMFErrorFilesystemKey,
								@"Mount has failed.", NSLocalizedDescriptionKey,
								nil];
	return [MFError errorWithDomain: kMFErrorDomain
							   code: kMFErrorCodeMountFaliure
						   userInfo: dictionary];
}


#pragma mark Accessors and Setters
- (void)setStatus:(NSString*)newStatus
{
	if (newStatus)
	{
		// Hack this a bit so that we can set an error on faliure
		// Do this only if an error hasn't already been set
		[statusInfo setObject: newStatus forKey:kMFSTStatusKey ];
		if( [newStatus isEqualToString: kMFStatusFSFailed] && 
			![statusInfo objectForKey: kMFSTErrorKey] )
		{
			NSError* error = nil;
			// Ask the delegate for the error
			if ([delegate respondsToSelector:@selector(errorForParameters:output:)] &&
				(error = [delegate errorForParameters:[self parametersWithImpliedValues] 
									  output:[statusInfo objectForKey: kMFSTOutputKey]]) && error)
			{
			}
			else
			{
				// Use a generic error
				error = [self errorForFaliure];
			}
			
			[statusInfo setObject: error forKey:kMFSTErrorKey ];
		}
	}
}


@synthesize plugin;
@end
