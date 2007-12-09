//
//  MFFilesystemController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 11/7/07.
//  Copyright 2007 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MFFilesystemController : NSObject {
	NSMutableArray* filesystems;
}

+ (MFFilesystemController*)sharedController;
- (void)loadFilesystems;

@property(readonly) NSArray* filesystems;

@end

