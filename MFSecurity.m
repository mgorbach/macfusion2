//
//  MFSecurity.m
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

#import "MFSecurity.h"
#import "MFFSDelegateProtocol.h"
#import "MFConstants.h"
#import "MFServerProtocol.h"
#import "MFLogging.h"
#import "MFServerFSProtocol.h"
#import "MFFilesystemController.h"
#import "MFClientFS.h"
#import "MFClientPlugin.h"
#import "MFNetworkFS.h"
#import "MFCore.h"

#define self @"MFSECURITY"

# pragma mark Keychain interaction
NSString *serviceNameForFS(MFFilesystem* fs) {
	return [NSString stringWithFormat: @"Macfusion: %@", fs.name];
}

NSDictionary *getGenericSecretsForFilesystemAndReturnItem(MFFilesystem *fs, SecKeychainItemRef *itemRef) {
	UInt32 passwordLength = 0;
	void *passwordData;
	NSString *serviceName = serviceNameForFS(fs);
	OSStatus error = SecKeychainFindGenericPassword(NULL,
													[serviceName lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
													[serviceName UTF8String],
													[fs.uuid lengthOfBytesUsingEncoding: NSUTF8StringEncoding],
													[fs.uuid UTF8String], 
													&passwordLength, 
													&passwordData, 
													itemRef);
	if (error == noErr) {
		// MFLogS(self, @"Found generic keychain entry");
		NSData* secretsData = [NSData dataWithBytes:passwordData length:passwordLength];
		// MFLogS(self, @"NSData from keycahin %@", secretsData);
		NSDictionary* loadedDataDict = [NSPropertyListSerialization propertyListFromData:secretsData mutabilityOption:NSPropertyListMutableContainers format:NULL errorDescription:nil];
		if ([loadedDataDict isKindOfClass:[NSDictionary class]]) {
			// MFLogS(self, @"Succesfully loaded secrets dictionary from keychain %@", loadedDataDict);
			SecKeychainItemFreeContent(NULL, passwordData);
			return loadedDataDict;
		} else {
			// MFLogS(self, @"Failed to parse data in generic entry. data: %@", loadedDataDict);
			return nil;
		}
	} else {
		return nil;
	}
}

NSDictionary *getNetworkSecretsForFilesystemAndReturnItem(MFFilesystem *fs, SecKeychainItemRef *itemRef) {
	UInt32 passwordLength = 0;
	void *passwordData;
	NSString *userName = [[fs parameters] objectForKey:kNetFSUserParameter];
	int port = [[[fs parameters] objectForKey:kNetFSPortParameter] intValue];
	NSString *hostName = [[fs parameters] objectForKey:kNetFSHostParameter];
	SecProtocolType protocol = [[[fs parameters] objectForKey:kNetFSProtocolParameter] intValue];
	
	if (userName && hostName && port && protocol) {
		OSStatus error = SecKeychainFindInternetPassword(NULL,[hostName lengthOfBytesUsingEncoding: NSUTF8StringEncoding],[hostName UTF8String],0,NULL,[userName lengthOfBytesUsingEncoding: NSUTF8StringEncoding],[userName UTF8String],0,NULL,port,protocol,
														  (SecAuthenticationType)NULL,&passwordLength,&passwordData,itemRef);
		if (error == noErr) {
			// MFLogS(self, @"Successfully found internet password for fs %@", fs);
			NSString *password = [NSString stringWithCString:passwordData encoding:NSUTF8StringEncoding];
			SecKeychainItemFreeContent(NULL,  passwordData);
			return [NSDictionary dictionaryWithObject: password forKey: kNetFSPasswordParameter];
		} else {
			// MFLogS(self, @"Error searching for internet password fs %@ error %d", fs, error);
		}
	} else {
		// MFLogS(self, @"No network info to search for fs %@", fs);
	}
	
	return nil;
}

NSDictionary *getGenericSecretsForFilesystem(MFFilesystem* fs) {
	return getGenericSecretsForFilesystemAndReturnItem(fs, NULL);
}

NSDictionary *getNetworkSecretsForFilesystem(MFFilesystem* fs) {
	return getNetworkSecretsForFilesystemAndReturnItem(fs, NULL);
}

NSDictionary *mfsecGetSecretsDictionaryForFilesystem(MFFilesystem* fs) {
	NSDictionary *genericSecretsDict = getGenericSecretsForFilesystem(fs);
	NSDictionary *networkSecretsDict = getNetworkSecretsForFilesystem(fs);
	NSMutableDictionary* secretsDictionary = [NSMutableDictionary dictionary];
	NSArray *secretsList = [[fs delegate] secretsList];
	for (NSString *secretKey in secretsList) {
		id genericSecret = [genericSecretsDict objectForKey: secretKey];
		id networkSecret = [networkSecretsDict objectForKey: secretKey];
		if (genericSecret) {
			[secretsDictionary setObject: genericSecret forKey: secretKey ];
		} else if (networkSecret) {
			[secretsDictionary setObject: networkSecret forKey: secretKey ];
		}
	}
	
	if ([secretsDictionary count] > 0) {
		return [secretsDictionary copy];
	} else {
		// MFLogS(self, @"Nothing useful in secrets dictionary. Returning nil");
		return nil;
	}
}

SecAccessRef keychainAccessRefForFilesystem(MFFilesystem* fs) {
	SecAccessRef accessRef;
	OSStatus error;
	
	NSArray *trustedApplicationPaths = mfcSecretClientsForFileystem(fs);
	NSMutableArray *trustRefs = [NSMutableArray array];
	for(NSString *path in trustedApplicationPaths) {
		SecTrustedApplicationRef trustedAppRef;
		error = SecTrustedApplicationCreateFromPath([path cStringUsingEncoding: NSUTF8StringEncoding], &trustedAppRef);
		if (error != noErr) {
			// MFLogSO(self, fs, @"Could not create trusted ref for path %@ fs %@ error %d", path, fs, error);
		} else {
			[trustRefs addObject: (id)trustedAppRef];
		}
	}
	
	error = SecAccessCreate((CFStringRef)serviceNameForFS( fs ), (CFArrayRef)[trustRefs copy], &accessRef);
	if (error != noErr) {
		// MFLogSO(self, fs, @"Failed to create access ref for fs %@ error %d", fs, error);
		return NULL;
	} else {
		return accessRef;
	}
}

void setNetworkSecretsForFilesystem (NSDictionary* secretsDictionary, MFFilesystem* fs ) {
	NSString *userName = [[fs parameters] objectForKey:kNetFSUserParameter];
	int port = [[[fs parameters] objectForKey:kNetFSPortParameter] intValue];
	NSString *hostName = [[fs parameters] objectForKey:kNetFSHostParameter];
	NSString *password = [secretsDictionary objectForKey:kNetFSPasswordParameter];
	SecProtocolType protocol = [[[fs parameters] objectForKey:kNetFSProtocolParameter] intValue];
	
	if (userName && hostName && port) {
		SecKeychainItemRef itemRef = NULL;
		if (getNetworkSecretsForFilesystemAndReturnItem(fs, &itemRef)) {
			if ([secretsDictionary count] == 0) {
				// Delete
				OSErr result = SecKeychainItemDelete( itemRef );
				if (result == noErr) {
					// MFLogS(self, @"Network keychain item deleted OK");
				} else {
					// MFLogSO(self, fs, @"Network keychain item deleted failed: %d", result);
				}
				
				return;				
			}
				
			// Modify
			OSStatus error = SecKeychainItemModifyContent(itemRef,NULL,[password lengthOfBytesUsingEncoding: NSUTF8StringEncoding],[password UTF8String]);
			if (error == noErr) {
				// MFLogS(self, @"Successfully modified network secrets for fs %@", fs );
			} else {
				// MFLogSO(self, fs, @"Failed to modify network secrets for fs %@. Error %d", fs, error);
			}
			
		} else {
			// Create
			SecKeychainAttribute attrs[] = {
				{ kSecLabelItemAttr, [hostName lengthOfBytesUsingEncoding: NSUTF8StringEncoding], (char *)[hostName UTF8String] },
				{ kSecAccountItemAttr, [userName lengthOfBytesUsingEncoding: NSUTF8StringEncoding], (char *)[userName UTF8String] },
				{ kSecServerItemAttr, [hostName lengthOfBytesUsingEncoding: NSUTF8StringEncoding], (char *)[hostName UTF8String] },
				{ kSecPortItemAttr, sizeof(int), (int *)&port },
				{ kSecProtocolItemAttr, sizeof(SecProtocolType), (SecProtocolType *)&protocol }
			};
			
			SecKeychainAttributeList attributes = {
				sizeof(attrs)/sizeof(attrs[0]), attrs
			};
			
			SecAccessRef accessRef = keychainAccessRefForFilesystem( fs );
			SecItemClass itemClass = kSecInternetPasswordItemClass;
			OSStatus error = SecKeychainItemCreateFromContent(itemClass, 
															  &attributes, 
															  [password lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
															  [password UTF8String],
															  NULL,
															  accessRef,
															  &itemRef);
			if (error == noErr) {
				// MFLogS(self, @"Successfully stored network secrets for fs %@", fs);
			} else {
				// MFLogSO(self, fs, @"Failed to store network secerets for fs %@. Error %d", fs, error);
			}
		}
			
	} else {
		// MFLogS(self, @"No network info to write for fs %@", fs);
	}
		
	return;
}

void setGenericSecretsForFilesystem(NSDictionary* secretsDictionary, MFFilesystem* fs) {
	NSString *serializationErrorString;
	
	if (![fs isPersistent]) {
		// MFLogS(self, @"Not setting generic secrets for temporary fs %@", fs);
		return;
	}
	
	NSData *secretsData = [NSPropertyListSerialization dataFromPropertyList:secretsDictionary format:NSPropertyListBinaryFormat_v1_0
														   errorDescription:&serializationErrorString];
	if (secretsData) {
		// MFLogS(self, @"Generic secrets serialized OK");
	} else	{
		// MFLogSO(self, fs, @"Could not serialize generic secrets dictionary for fs %@", fs);
		return;
	}
	
	SecKeychainItemRef itemRef = NULL;
	if (getGenericSecretsForFilesystemAndReturnItem(fs, &itemRef) || itemRef ) {
		if ([secretsDictionary count] == 0) {
			// Delete
			OSErr result = SecKeychainItemDelete( itemRef );
			if (result == noErr) {
				// MFLogS(self, @"Generic keychain item deleted OK");
			} else {
				// MFLogSO(self, fs, @"Generic keychain item deleted failed: %d fs %@", result, fs);
			}
			
			return;
		}
		
		// Modify
		OSErr result = SecKeychainItemModifyContent(itemRef,
													NULL,
													[secretsData length],
													[secretsData bytes]);
		if (result == noErr) {
			// MFLogSO(self, fs, @"Generic keychain data updated succesfully fs %@", fs);
			return;
		} else {
			// MFLogSO(self, fs, @"Failed to update generatic keychain data for fs %@. Result %d", fs, result);
		}
	} else {
		// Create
		NSString *serviceName = serviceNameForFS(fs);
		SecItemClass itemClass = kSecGenericPasswordItemClass;
		SecAccessRef accessRef = keychainAccessRefForFilesystem(fs);
		if (accessRef == NULL) {
			// MFLogSO(self, fs, @"Null access ref for fs %@. Returning", fs);
			return;
		}
		
		SecKeychainAttribute attrs[] = {
			{ kSecLabelItemAttr, [serviceName lengthOfBytesUsingEncoding: NSUTF8StringEncoding], (char*)[serviceName UTF8String] },
			{ kSecAccountItemAttr, [fs.uuid lengthOfBytesUsingEncoding: NSUTF8StringEncoding], (char*)[fs.uuid UTF8String] },
			{ kSecServiceItemAttr, [serviceName lengthOfBytesUsingEncoding: NSUTF8StringEncoding], (char*)[serviceName UTF8String] }
		};
		
		SecKeychainAttributeList attributes = {
			sizeof(attrs)/sizeof(attrs[0]), attrs
		};
		
		OSErr result = SecKeychainItemCreateFromContent(itemClass,
														&attributes,
														[secretsData length],
														[secretsData bytes],
														NULL,
														accessRef,
														&itemRef);
		
		CFRelease(accessRef);
		if (result == noErr) {
			// MFLogS(self, @"Generic keychain data created succesfully");
			return;
		} else {
			// MFLogSO(self, fs, @"Failed to create generic keychain data for fs %@. Result %d", fs, result);
			return;
		}
	}
}

void mfsecSetSecretsDictionaryForFilesystem(NSDictionary *secretsDictionary, MFFilesystem *fs) {
	// MFLogS(self, @"Setting secrets dict %@ for fs %@", secretsDictionary, fs);
	if (!secretsDictionary) {
		// MFLogSO(self, fs, @"Secrets dictionary nil for fs %@. Nothing to store to keychain", fs);
		return;
	}
	
	setGenericSecretsForFilesystem(secretsDictionary, fs);
	setNetworkSecretsForFilesystem(secretsDictionary, fs);
}

# pragma mark Token authentication
MFClientFS *mfsecGetFilesystemForToken(NSString* token) {
	id <MFServerProtocol> server = (id<MFServerProtocol>)[NSConnection rootProxyForConnectionWithRegisteredName:kMFDistributedObjectName host:nil];
	if (server)	{
		id <MFServerFSProtocol> remoteFS = (id <MFServerFSProtocol>)[server filesystemForToken:token];
		if (remoteFS) {
			MFClientPlugin *clientPlugin = [[MFClientPlugin alloc] initWithRemotePlugin: [remoteFS plugin]];
			MFClientFS *fs = [MFClientFS clientFSWithRemoteFS: remoteFS clientPlugin:clientPlugin];
			return fs;
		} else {
			return nil;
		}
	} else {
		// MFLogS(self, @"Can not connect to server to authenticate token %@", token);
		return nil;
	}
}

NSString *mfsecTokenForFilesystemWithUUID(NSString *uuid) {
	 id <MFServerProtocol> server = (id<MFServerProtocol>)[NSConnection rootProxyForConnectionWithRegisteredName:kMFDistributedObjectName host:nil];
	NSString* token = [server tokenForFilesystemWithUUID:uuid];
	// MFLogS(self, @"Token generated for uuid %@: %@", uuid, token);
	return token;
}

# pragma mark UI
SInt32 showDialogForPasswordQuery(MFFilesystem* fs, BOOL* savePassword, NSString** password)
{
	// Icon URL from fs
	const void* keychainKeys[] = {
		kCFUserNotificationAlertHeaderKey,
		kCFUserNotificationAlertMessageKey,
		kCFUserNotificationTextFieldTitlesKey,
		kCFUserNotificationCheckBoxTitlesKey,
		kCFUserNotificationAlternateButtonTitleKey,
		kCFUserNotificationIconURLKey
	};
	
	
	NSString* iconURL = [NSURL fileURLWithPath: fs.iconPath];
	NSString* userName = [[fs parameters] objectForKey: kNetFSUserParameter];
	NSString* host = [[fs parameters] objectForKey: kNetFSHostParameter];
	NSString* dialogText = [NSString stringWithFormat: @"Please enter network password for host %@ user %@",host, userName];
	
	const void* keychainValues[] = {
		@"Password Needed",
		dialogText,
		@"Password",
		@"Save Password in Keychain",
		@"Cancel",
		iconURL
	};
	
	SInt32 error;
	CFDictionaryRef dialogTemplate = CFDictionaryCreate(kCFAllocatorDefault,
										keychainKeys,
										keychainValues,
										sizeof(keychainKeys)/sizeof(*keychainKeys),
										&kCFTypeDictionaryKeyCallBacks,
										&kCFTypeDictionaryValueCallBacks);
	CFUserNotificationRef passwordDialog = CFUserNotificationCreate(kCFAllocatorDefault,
																	0,
																	kCFUserNotificationPlainAlertLevel | CFUserNotificationSecureTextField(0),
																	&error, dialogTemplate);
	if (error) {
		// MFLogSO(self, fs, @"Dialog error received %d fs %@", error, fs);
	}

	CFOptionFlags responseFlags;
	error = CFUserNotificationReceiveResponse(passwordDialog, 0, &responseFlags);
	
	if (error) {
		// MFLogSO(self, fs, @"Dialog error received after received fs %@ response %d", fs, error);
	}
	
	CFRelease(dialogTemplate);
	CFRelease(passwordDialog);
	int button = responseFlags & 0x3;
	if (button == kCFUserNotificationAlternateResponse) {
		// MFLogSO(self, fs, @"Exiting due to cancel on UI fs %@", fs);
		return 1;
	}
	
	// This is a hack, checking responseFlags with and correctly wasn't working for some reason
	*savePassword = (responseFlags == 256); 

	// MFLogSO(self, fs, @"Save password is %d Flags %d fs %@", savePassword, responseFlags, fs);
	CFStringRef passwordRef = CFUserNotificationGetResponseValue(passwordDialog,kCFUserNotificationTextFieldValuesKey,
																 0);
	*password = (NSString *)passwordRef;
	CFRelease(passwordRef);
	
	return 0;
}

NSString *mfsecQueryForFSNetworkPassword(MFClientFS* fs) {
	NSDictionary* secrets = mfsecGetSecretsDictionaryForFilesystem( fs );
	if ([secrets objectForKey:kNetFSPasswordParameter]) {
		// MFLogSO(self, fs, @"Should not be querying if we already have a password fs %@", fs);
		return nil;
	}
	
	NSString *password = nil;
	BOOL save;
	[fs setPauseTimeout: YES];
	SInt32 result = showDialogForPasswordQuery(fs, &save, &password);
	[fs setPauseTimeout: NO];
	if (result != 0) {
		// MFLogSO(self, fs, @"UI query received results %d fs %@", result, fs);
		return nil;
	}
	
	if (save && [password length] > 0) {
		// MFLogSO(self, fs, @"Updating secrets fs %@", fs);
		NSMutableDictionary* updatedSecrets = secrets ? [secrets mutableCopy] : [NSMutableDictionary dictionary];
		[updatedSecrets setObject: password forKey: kNetFSPasswordParameter ];
		mfsecSetSecretsDictionaryForFilesystem([updatedSecrets copy], fs);
	} else {
		// MFLogSO(self, fs, @"Not updating secrets %@", fs);
	}
	
	return password;
}

NSString *mfsecUUIDForKeychainItemRef(SecKeychainItemRef itemRef) {
	SecKeychainAttributeInfo attrInfo;
	UInt32 tag = kSecAccountItemAttr;
	attrInfo.tag = &tag;
	attrInfo.format = NULL;
	attrInfo.count = 1;
	SecKeychainAttributeList *attrList = NULL;
	SecKeychainAttribute *attr = NULL;

	SecKeychainItemCopyAttributesAndData(itemRef, &attrInfo, NULL, &attrList, NULL, NULL);
	// MFLogS(self, @"Loaded %d attrs", attrList->count);
	attr = attrList -> attr;
	NSString *uuid = [NSString stringWithCString:attr->data encoding:NSUTF8StringEncoding];
	SecKeychainItemFreeAttributesAndData(attrList, NULL);
	return uuid;
}