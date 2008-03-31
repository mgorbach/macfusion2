//
//  MFLogViewerTableView.m
//  MacFusion2
//
//  Created by Michael Gorbach on 3/24/08.
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

#import "MFLogViewerTableView.h"
#import "MFLogViewerTableCell.h"
#import "MFLogReader.h"
#import "MFLogging.h"

@implementation MFLogViewerTableView

+ (void)initialize
{
	return [self exposeBinding:@"logMessages"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
	if (self = [super initWithCoder:decoder])
	{
		// NSLog(@"Init with coder");
		[self setDelegate: self];
		[self setDataSource: self];
		[[[self tableColumns] objectAtIndex: 0] setDataCell:
		 [MFLogViewerTableCell new]];
		[self addObserver:self
			   forKeyPath:@"logMessages"
				  options:(NSKeyValueObservingOptions)0 context:self];
	}
	
	return self;
}

- (int) numberOfRowsInTableView: (NSTableView *) tableView
{
	return [logMessages count];
}

- (id) tableView: (NSTableView *) tableView
objectValueForTableColumn: (NSTableColumn *) tableColumn
			 row: (int) row
{
	return [(NSDictionary*)[logMessages objectAtIndex: row]
			objectForKey: [NSString stringWithUTF8String: ASL_KEY_MSG]];
}

- (void) tableView: (NSTableView *) tableView 
   willDisplayCell: (NSCell*) cell 
	forTableColumn: (NSTableColumn *) tableColumn 
			   row: (int) row
{
	[cell setRepresentedObject: 
	 [logMessages objectAtIndex: row]];
}

- (void)viewDidEndLiveResize
{
	[self noteHeightOfRowsWithIndexesChanged: 
	 [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, [self.logMessages count])]];
	[self setNeedsDisplay];
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	CGFloat cellHeight = [(MFLogViewerTableCell*)[self preparedCellAtColumn:0 row:row]
			heightForCellInWidth: [self visibleRect].size.width];
	return cellHeight != 0 ? cellHeight : [self rowHeight];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	// NSLog(@"Change observed in tableView");
    if (context == self) {
		[self reloadData];
		[self noteHeightOfRowsWithIndexesChanged: 
		 [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(0, [self.logMessages count])]];
	}
	else {
		 [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

# pragma markr C&P
- (void)copy:(id)sender
{
//	MFLogS(self, @"Copy");
	NSPasteboard* pb = [NSPasteboard generalPasteboard];
	[pb declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner:self];
	NSMutableString* stringData = [NSMutableString new];
	NSIndexSet* indexes = [self selectedRowIndexes];
	NSInteger index = [indexes firstIndex];
	NSInteger i;
	for(i=0; i < [indexes count]; i++)
		[stringData appendString:
		 [NSString stringWithFormat: @"%@ %@\n", headerStringForASLMessageDict([self.logMessages objectAtIndex: index]),
		  [[self.logMessages objectAtIndex: i] objectForKey: kMFLogKeyMessage]]];
	[pb setData: [stringData dataUsingEncoding: NSUTF8StringEncoding] forType: NSStringPboardType];
	return;
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
	if ([item action] == @selector(copy:))
		return YES;
	else
		return [super validateUserInterfaceItem: item];
}

# pragma mark Tooltip
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell
				   rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn 
					row:(NSInteger)row 
		  mouseLocation:(NSPoint)mouseLocation
{
	return [NSString stringWithFormat: @"%@", [self.logMessages objectAtIndex: row]];
}

@synthesize logMessages;
@end
