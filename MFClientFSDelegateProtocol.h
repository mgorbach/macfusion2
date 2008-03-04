/*
 *  MFClientFSDelegateProtocol.h
 *  MacFusion2
 *
 *  Created by Michael Gorbach on 3/3/08.
 *  Copyright 2008 Michael Gorbach. All rights reserved.
 *
 */

@class MFClientFS;

@protocol MFClientFSDelegateProtocol <NSObject>
- (void)filesystemDidChangeStatus:(MFClientFS*)fs;
@end