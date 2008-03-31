/*
 *  MFConstants.h
 *  MacFusion2
 */

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
#define kMFFSAdvancedOptionsParameter @"advancedOptions"

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



