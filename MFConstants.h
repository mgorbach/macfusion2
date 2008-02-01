/*
 *  MFConstants.h
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 12/1/07.
 *  Copyright 2007 Michael Gorbach. All rights reserved.
 *
 */

// Status values for filesystems
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

// More key Names
#define kMFPluginShortNameKey @"MFPluginShortName"
#define kMFPluginLongNameKey @"MFPluginLongName"
