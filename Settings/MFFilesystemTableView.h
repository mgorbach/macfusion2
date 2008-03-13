//
//  MFFilesystemTableView.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/8/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MFSettingsController;

@interface MFFilesystemTableView : NSTableView
{
	NSUInteger mountPushedRow;
	NSUInteger editPushedRow;
	NSUInteger editHoverRow;
	NSUInteger mountHoverRow;
	NSMutableArray* filesystems;
	MFSettingsController* controller;
	BOOL eatEvents;
}

@property(retain, readwrite) NSMutableArray* filesystems;
@property(retain, readwrite) MFSettingsController* controller;
@end
