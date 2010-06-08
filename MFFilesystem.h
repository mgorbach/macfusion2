//
//  MFFilesystem.h
//  MacFusion2
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
#import "MFFSDelegateProtocol.h"

@class MFPlugin;

@interface MFFilesystem : NSObject {
	NSMutableDictionary* parameters;
	NSMutableDictionary* statusInfo;
	id <MFFSDelegateProtocol> delegate;
	NSMutableDictionary* secrets;
}


// Key action methods
- (void)mount;
- (void)unmount;

// shortcut methods
- (BOOL)isMounted;
- (BOOL)isWaiting;
- (BOOL)isUnmounted;
- (BOOL)isFailedToMount;
- (BOOL)isPersistent;

- (NSMutableDictionary*)parametersWithImpliedValues;
- (NSArray*)parameterList;
- (id)valueForParameterNamed:(NSString*)paramName;
- (NSMutableDictionary*)fillParametersWithImpliedValues:(NSDictionary*)params;
- (NSError*)error;
- (id <MFFSDelegateProtocol>)delegate;
- (void)updateSecrets;

@property(readwrite, assign) NSString* status;
@property(readonly, assign) NSString* uuid;
@property(readonly) NSString* mountPath;
@property(readonly) NSString* name;
@property(readonly) NSMutableDictionary* parameters;
@property(readonly) NSDictionary* statusInfo;
@property (readwrite, retain) NSMutableDictionary* secrets;
@property(readonly) NSString* pluginID;
@property(readonly) NSString* descriptionString;
@property(readonly) NSString* iconPath;
@property(readonly) NSString* filePath;
@property(readonly) NSString* imagePath;

@end
