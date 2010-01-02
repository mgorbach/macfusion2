//
//  MFAdvancedViewController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/20/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MFIconSettingImageView;
@interface MFAdvancedViewController : NSViewController {
	IBOutlet MFIconSettingImageView *iconView;
}

- (IBAction)chooseIcon:(id)sender;

@end
