//
//  MGTestView.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/30/08.
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

#import "MGTestView.h"
#import <stdlib.h>

@implementation MGTestView

- (NSArray*)randomColors
{
	return [NSArray arrayWithObjects: 
			[NSColor blueColor], [NSColor greenColor],
			[NSColor orangeColor], [NSColor yellowColor],
			[NSColor cyanColor], [NSColor redColor],
			nil];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		long rand = random() % 6;
		color = [[self randomColors] objectAtIndex: rand];
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	[color set];
	[NSBezierPath setDefaultLineWidth: 2.0];
	[NSBezierPath strokeRect: rect];
	[NSBezierPath fillRect: rect];
	[super drawRect: rect];
}

@end
