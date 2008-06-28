//
//  MFPreferences.h
//  MacFusion2
//
//  Created by Michael Gorbach on 3/15/08.
//  Copyright 2008 Michael Gorbach. All rights reserved.
//
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

#import <Cocoa/Cocoa.h>
// Preference Keys
#define kMFPrefsAutoloadMenuling @"Autoload Menuling"
#define kMFPrefsAutoScrollLog @"AutoScroll Log"
#define kMFPrefsTimeout @"timeout"
#define kMFPrefsAutosize @"autosize"

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
- (void)readPrefsFromDisk;

@end
