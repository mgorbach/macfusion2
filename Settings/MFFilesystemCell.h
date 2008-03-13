//
//  MFFilesystemCell.h
//  MacFusion2
//
//  Created by Michael Gorbach on 1/17/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MFClientFS;

@interface MFFilesystemCell : NSActionCell {
	BOOL editPushed, mountPushed;
}

- (void) addTrackingAreasForView: (NSView *) controlView inRect: (NSRect) cellFrame withUserInfo: (NSDictionary *) userInfo
				   mouseLocation: (NSPoint) mouseLocation;
- (BOOL)editButtonEnabled;
- (BOOL)mountButtonEnabled;

@property(readwrite) BOOL editPushed;
@property(readwrite) BOOL mountPushed;
@end
