//
//  MGTransitioningTabView.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/5/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CIFilter;

@interface MGTransitioningTabView : NSTabView {
	NSRect imageRect;
	CIFilter* transitionFilter;
	NSAnimation* animation;
}
@end

@interface TabViewAnimation : NSAnimation {
}
@end



