//
//  MFPreferences.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
// Preference Keys
#define kMFPrefsAutoloadMenuling @"Autoload Menuling"

@interface MFPreferences : NSObject {
	NSMutableDictionary* prefsDict;
	BOOL firstTimeRun;
}

+ (MFPreferences*) sharedPreferences;
- (id)getValueForPreference:(NSString*)prefKey;
- (void)setValue:(id)value 
   forPreference:(NSString*)prefKey;
- (void)setBool:(BOOL)value forPreference:(NSString*)prefKey;
- (BOOL)getBoolForPreference:(NSString*)prefKey;

@end
