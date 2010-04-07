//
//  MFFilesystemTableView.m
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

#import "MFFilesystemTableView.h"
#import "MFFilesystemCell.h"
#import "MFSettingsController.h"
#import "MFClient.h"
#import "MFConstants.h"
#import "MFClientFS.h"
#import "MGNSImage.h"
#import "MFMountToggleButtonCell.h"

@implementation MFFilesystemTableView

+ (void)initialize
{
	[self exposeBinding:@"filesystems"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
	if (self = [super initWithCoder:decoder])
	{
		[self setDelegate: self];
		self.filesystems = [NSMutableArray array];
		MFFilesystemCell* cell = [MFFilesystemCell new];
		[[[self tableColumns] objectAtIndex:0] setDataCell: cell];
//		[self setDataSource: self];
		[self registerForDraggedTypes: [NSArray arrayWithObjects: kMFFilesystemDragType, NSFilesPromisePboardType, nil ]];
		[self setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
		[self setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
		NSPointerFunctionsOptions options = NSPointerFunctionsObjectPointerPersonality;
		progressIndicators = [[NSMapTable alloc] initWithKeyOptions:options|NSPointerFunctionsZeroingWeakMemory
													   valueOptions:options capacity: [self.filesystems count] ];
	}
	
	return self;
}

- (void) awakeFromNib
{
}

- (void)viewDidEndLiveResize
{
	[self setNeedsDisplay];
}


- (MFClientFS*)clickedFilesystem
{
	NSInteger row = [self clickedRow];
	if (row >= 0 && row < [self.filesystems count])
		return [self.filesystems objectAtIndex: row];
	else
		return nil;
}

- (void) tableView: (NSTableView *) tableView 
   willDisplayCell: (NSCell*) cell 
	forTableColumn: (NSTableColumn *) tableColumn 
			   row: (int) row
{
	MFClientFS* fs = [self.filesystems objectAtIndex: row];
	if ([[tableColumn identifier] isEqualTo: @"main"])
	{
		MFFilesystemCell* theCell = (MFFilesystemCell*)cell;
		[theCell setRepresentedObject: fs];
	}
	if ([[tableColumn identifier] isEqualTo: @"mount"])
	{
		MFMountToggleButtonCell* theCell = (MFMountToggleButtonCell*)cell;
		[theCell setRepresentedObject: fs];
	}
}

- (void)statusChangedForFS:(MFClientFS*)fs
{
	MFFilesystemCell* cell = (MFFilesystemCell*)[self preparedCellAtColumn:0 row:[self.filesystems indexOfObject: fs]];
	[cell clearImageForFS: fs];
	[self setNeedsDisplayInRect: [self rectOfRow: [self.filesystems indexOfObject: fs]]];
	NSProgressIndicator* indicator = [progressIndicators objectForKey: fs];
	NSInteger row = [self.filesystems indexOfObject: fs];
	if ([fs isWaiting])
	{
		if (!indicator)
		{
			indicator = [NSProgressIndicator new];
			[indicator setStyle: NSProgressIndicatorSpinningStyle];
			[indicator setControlTint: NSClearControlTint ];
			[progressIndicators setObject: indicator 
								   forKey: fs ];
		}
		NSRect indicatorRect = [ (MFFilesystemCell*)[self preparedCellAtColumn:0 row: row] 
								progressIndicatorRectInRect: [self rectOfRow: row] ];
		indicatorRect.origin.x += [self intercellSpacing].width/2;
		[indicator setFrame: indicatorRect ];
		[self addSubview: indicator];
		[indicator startAnimation: self];
	}
	else
	{
		if (indicator)
		{
			[indicator stopAnimation: self];
			[indicator removeFromSuperview];
		}
	}
	
	[self setNeedsDisplayInRect: [self rectOfRow: row]];
}
 

- (void)keyDown:(NSEvent*)event
{
	BOOL handled = [[self menu] performKeyEquivalent: event];
	
	if ([event keyCode] == 53)
	{
		[self deselectAll: self];
		handled = YES;
	}
	
	if (!handled)
		[super keyDown: event];		
}

# pragma mark D&D

- (BOOL)tableView:(NSTableView *)tableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
	 toPasteboard:(NSPasteboard*)pboard
{
	NSMutableArray* uuids = [NSMutableArray array];
	NSUInteger count = [rowIndexes count];
	
	int i;
	NSUInteger index = [rowIndexes firstIndex];
	for(i = 0; i < count; i++)
	{
		NSString* uuid = [ (MFClientFS*)[self.filesystems objectAtIndex: index] uuid];
		[uuids addObject: uuid];
		index = [rowIndexes indexGreaterThanIndex:index];
	}
	
	if ([uuids count] > 0)
	{
		[pboard declareTypes:[NSArray arrayWithObjects:kMFFilesystemDragType, NSFilesPromisePboardType, nil] owner:self];
		[pboard setPropertyList:uuids forType:kMFFilesystemDragType];
		[pboard setPropertyList: [NSArray arrayWithObjects: @"fusion", nil] forType:NSFilesPromisePboardType];
		return YES;
	}
	else
	{
		return NO;
	}
	
	
}

-(NSArray*)tableView:(MFFilesystemTableView*)tableView
namesOfPromisedFilesDroppedAtDestination:(NSURL*)dest
forDraggedRowsWithIndexes:(NSIndexSet*)indexes
{
	NSInteger index = [indexes firstIndex];
	NSInteger i;
	NSMutableArray* files = [NSMutableArray array];
	for( i=0; i < [indexes count]; i++ )
	{
		MFClientFS* fs = [self.filesystems objectAtIndex: index];
		NSString* filename = [[MFClient sharedClient] createMountIconForFilesystem:fs
														   atPath:dest];
		[files addObject: filename];
	}
	
	return [files copy];
}

- (NSDragOperation)tableView:(NSTableView*)tableView 
				validateDrop:(id <NSDraggingInfo>)info 
				 proposedRow:(int)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	[tableView setDropRow:row dropOperation:NSTableViewDropAbove];
	return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSPasteboard* pb = [info draggingPasteboard];
	// Store old selection
	NSArray* selectedItems = [self.filesystems objectsAtIndexes: [self selectedRowIndexes]];
	
	// Move stuff
	NSArray* uuidsBeingMoved = [pb propertyListForType:kMFFilesystemDragType];
	[[MFClient sharedClient] moveUUIDS:uuidsBeingMoved toRow:row];
	
	// Preserve Selection
	NSMutableIndexSet* toSelect = [NSMutableIndexSet indexSet];
	for(id object in selectedItems)
	{
		[toSelect addIndex: [self.filesystems indexOfObject: object]];
	}
	[self selectRowIndexes: toSelect byExtendingSelection:NO];
	return YES;
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)theRowIndexes
							tableColumns:(NSArray *)theTableColumns
								   event:(NSEvent *)theEvent
								  offset:(NSPointPointer)theOffset
{
	// We're going to be stupid and take on the first selected filesystem's icon
	NSInteger fsRowIndex = [theRowIndexes firstIndex];
	MFFilesystemCell* cell = (MFFilesystemCell*)[self preparedCellAtColumn:0 row: fsRowIndex];
	NSImage* icon = [cell iconToDraw];
	[icon setFlipped: NO];
	return icon;
}

 
@synthesize filesystems, controller;
@end
