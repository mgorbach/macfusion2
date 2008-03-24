//
//  MFCore.h
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
#import "MFFilesystem.h"

#define kMFMainBundleIdentifier @"org.mgorbach.macfusion2"
#define kMFAgentBundleIdentifier @"org.mgorbach.macfusion2.macfusionAgent"
#define kMFMenulingBundleIdentifier @"org.mgorbach.macfusion2.menuling"


// Locations of clients
NSString* mfcMainBundlePath();
NSString* mfcMenulingBundlePath();
NSArray* mfcSecretClientsForFileystem( MFFilesystem* fs );
NSString* mfcAgentBundlePath();

// Launch Services and Login Items Control
BOOL mfcGetStateForAgentLoginItem();
BOOL mfcSetStateForAgentLoginItem(BOOL state);
BOOL mfcGetStateForMenulingLoginItem();
BOOL mfcSetStateForMenulingLoginItem(BOOL state);

// Clients
BOOL mfcClientIsUIElement();
void mfcLaunchAgent();


// FUSE versioning
NSString* mfcGetMacFuseVersion();