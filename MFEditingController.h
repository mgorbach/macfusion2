//
//  MFEditingController.h
//  MacFusion2
//
//  Created by Michael Gorbach on 6/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
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

#define kMFEditReturnOK 0
#define kMFEditReturnCancel 1

@class MFClientFS;

@interface MFEditingController : NSWindowController {
	MFClientFS* fsBeingEdited;

}

+ (NSInteger)editFilesystem:(MFClientFS*)fs onWindow:(NSWindow*)window;
@end
