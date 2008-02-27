/*
 *  MFConstants.h
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 12/1/07.
 *  Copyright 2007 Michael Gorbach. All rights reserved.
 *
 */

// Status values for filesystems
/*
extern NSString* kMFStatusFSMounted;
extern NSString* kMFStatusFSUnmounted;
extern NSString* kMFStatusFSWaiting;
extern NSString* kMFStatusFSFailed;

// Notification Names
extern NSString* kMFStatusChangedNotification;
extern NSString* kMFFilesystemAddedNotification;
extern NSString* kMFFilesystemRemovedNotification;

// IPC
extern NSString* kMFDNCObject;
extern NSString* kMFDistributedObjectName;

// Key Names
extern NSString* kMFFilesystemNameKey;
extern NSString* kMFFilesystemUUIDKey;
extern NSString* kMFFilesystemStatusKey;
*/
 
// Status
#define kMFStatusFSMounted @"Mounted"
#define kMFStatusFSUnmounted @"Unmounted"
#define kMFStatusFSWaiting @"Waiting to Mount"
#define kMFStatusFSFailed @"Failed to Mount"

// IPC Distribution Notifications
#define kMFStatusChangedNotification @"org.mgorbach.macfusion.notifications.statusChanged"
#define kMFFilesystemAddedNotification @"org.mgorbach.macfusion.notifications.fsAdded"
#define kMFFilesystemRemovedNotification @"org.mgorbach.macfusion.notifications.fsRemoved"
#define kMFRecentsUpdatedNotification @"org.mgorbach.macfusion.notifications.recentsUpdated"

// Client Notifications (Non-distributed)
#define kMFClientFSMountedNotification @"org.mgorbach.macfusion.mfclient.fsMounted"
#define kMFClientFSUnmountedNotification @"org.mgorbach.macfusion.mfclient.fsUnmounted"
#define kMFClientFSFailedNotification @"org.mgorbach.macfusion.mfclient.fsFailed"

// IPC Object Names
#define kMFDNCObject @"org.mgorbach.macfusion"
#define kMFDistributedObjectName @"org.mgorbach.macfusion.do"

// Keys for Notifications
#define kMFFilesystemNameKey @"Name"
#define kMFFilesystemStatusKey @"Status"
#define kMFRecentKey @"recent"

// Parameters Common to All FUSE Filesystems
#define kMFFSNameParameter @"Name"
#define kMFFSTypeParameter @"Type"
#define kMFFSVolumeNameParameter @"Volume Name"
#define kMFFSVolumeIconPathParameter @"Icon Path"
#define kMFFSMountPathParameter @"Mount Path"
#define KMFFSUUIDParameter @"UUID"
#define kMFFSFilePathParameter @"File Path"
#define kMFFSPersistentParameter @"Is Persistent"
#define kMFFSDescriptionParameter @"Description"

// Status keys
#define KMFStatusDict @"statusInfo"
#define kMFParameterDict @"parameters"

#define kMFSTErrorKey @"error"
#define kMFSTStatusKey @"status"
#define kMFSTOutputKey @"output"

// More key Names
#define kMFPluginShortNameKey @"MFPluginShortName"
#define kMFPluginLongNameKey @"MFPluginLongName"

// Error handling
#define kMFErrorDomain @"org.mgorbach.macfusion.errordomain"
enum macfusionErrorCodes {
	kMFErrorCodeInvalidPath,
	kMFErrorCodeDataCannotBeRead,
	kMFErrorCodeMissingParameter,
	kMFErrorCodeInvalidParameterValue,
	kMFErrorCodeNoPluginFound,
	kMFErrorCodeMountFaliure
};

#define kMFErrorParameterKey @"parameter"
#define kMFErrorFilesystemKey @"filesystem"
#define KMFErrorPluginKey @"plugin"
#define kMFErrorValueKey @"value"

// Exceptions
#define kMFBadAPIUsageException @"Bad API Usage In Macfusion"


