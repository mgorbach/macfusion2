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
#define kMFFilesystemNameKey @"name"
#define kMFFilesystemStatusKey @"status"
#define kMFRecentKey @"recent"

// Parameters Common to All FUSE Filesystems
#define kMFFSNameParameter @"name"
#define kMFFSTypeParameter @"type"
#define kMFFSVolumeNameParameter @"volumeName"
#define kMFFSVolumeIconPathParameter @"iconPath"
#define kMFFSMountPathParameter @"mountPath"
#define KMFFSUUIDParameter @"uuid"
#define kMFFSFilePathParameter @"filePath"
#define kMFFSPersistentParameter @"isPersistent"
#define kMFFSDescriptionParameter @"description"
#define kMFFSVolumeImagePathParameter @"imagePath"

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
	kMFErrorCodeMountFaliure,
	kMFErrorCodeCustomizedFaliure
};

#define kMFErrorParameterKey @"parameter"
#define kMFErrorFilesystemKey @"filesystem"
#define KMFErrorPluginKey @"plugin"
#define kMFErrorValueKey @"value"


// Exceptions
#define kMFBadAPIUsageException @"Bad API Usage In Macfusion"

// D&D
#define kMFFilesystemDragType @"org.mgorbach.macfusion.drag.mffilesystem"

// UI Keys
extern NSString* kMFUIMainViewKey;
extern NSString* kMFUIAdvancedViewKey;
extern NSString* kMFUIMacfusionAdvancedViewKey;

