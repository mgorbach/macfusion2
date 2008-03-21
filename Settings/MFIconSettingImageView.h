//
//  MFIconSettingImageView.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/19/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MFClientFS;

@interface MFIconSettingImageView : NSView {
	MFClientFS* fs;
	CIImage* normalImage;
	CIImage* selectedImage;
	BOOL dragHighlight;
}

@property(readwrite, retain) MFClientFS* fs;
@end
