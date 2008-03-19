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

@implementation MFFilesystemTableView

+ (void)initialize
{
	[self exposeBinding:@"filesystems"];
}

- (id) initWithCoder: (NSCoder *) decoder
{
	if (self = [super initWithCoder:decoder])
	{
		mountPushedRow = NSNotFound;
		editPushedRow = NSNotFound;
		editHoverRow = NSNotFound;
		mountHoverRow = NSNotFound;
		[self setDelegate: self];
		self.filesystems = [NSMutableArray array];
		MFFilesystemCell* cell = [MFFilesystemCell new];
		[[[self tableColumns] objectAtIndex:0] setDataCell: cell];
		[self setDataSource: self];
		eatEvents = NO;
		[self registerForDraggedTypes: [NSArray arrayWithObjects: kMFFilesystemDragType, NSFilesPromisePboardType, nil ]];
		[self setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
		[self setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
	}
	
	return self;
}

- (void) awakeFromNib
{
}

- (void) updateTrackingAreas
{
	[super updateTrackingAreas];
	for(NSTrackingArea* area in [self trackingAreas])
		[self removeTrackingArea: area];
	
	NSRange rows = [self rowsInRect: [self visibleRect]];
	if (rows.length == 0)
		return;
	
	NSUInteger row;
	for (row = rows.location; row < NSMaxRange(rows); row++)
	{
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: row]
															 forKey: @"Row"];
		MFFilesystemCell* cell = (MFFilesystemCell*)[self preparedCellAtColumn:0 row:row];
		[cell addTrackingAreasForView:self 
							   inRect:[self rectOfRow:row]
						 withUserInfo:userInfo
						mouseLocation: [NSEvent mouseLocation]];
	}
}

- (void)viewDidEndLiveResize
{
	[self setNeedsDisplay];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
//	NSLog(@"delegate %@", [self delegate]);
//	NSLog(@"Mouse entered theEvent %@ userData %@", theEvent, [theEvent userData]);
	eatEvents = YES;
	NSDictionary* userData = [theEvent userData];
	if ([[userData objectForKey:@"Type"] isEqualTo:@"Mount"])
	{
		mountHoverRow = [[userData objectForKey:@"Row"] intValue];
	}
	else if ([[userData objectForKey:@"Type"] isEqualTo:@"Edit"])
	{
		editHoverRow = [[userData objectForKey:@"Row"] intValue];
	}
}

- (void)mouseExited:(NSEvent *)theEvent
{
//	NSLog(@"Mouse exited");
	editHoverRow = NSNotFound;
	mountHoverRow = NSNotFound;
	eatEvents = NO;
}


- (void)mouseDown:(NSEvent*)theEvent
{
	if (!eatEvents)
	{
		[super mouseDown: theEvent];
		return;
	}
	NSPoint point = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	NSInteger row = [self rowAtPoint:point];
	editPushedRow = editHoverRow;
	mountPushedRow = mountHoverRow;
	
	[self setNeedsDisplayInRect: [self rectOfRow: row]];
}

- (MFClientFS*)clickedFilesystem
{
	NSInteger row = [self clickedRow];
	if (row > 0 && row < [self.filesystems count])
		return [self.filesystems objectAtIndex: row];
	else
		return nil;
}

- (void) tableView: (NSTableView *) tableView 
   willDisplayCell: (NSCell*) cell 
	forTableColumn: (NSTableColumn *) tableColumn 
			   row: (int) row
{
	MFFilesystemCell* theCell = (MFFilesystemCell*)cell;
	[theCell setRepresentedObject: [self.filesystems objectAtIndex: row]];
	[theCell setEditPushed: (row == editPushedRow) && [theCell editButtonEnabled]];
	[theCell setMountPushed: (row == mountPushedRow) && [theCell mountButtonEnabled]];
}

- (void)mouseUp:(NSEvent*)theEvent
{
	[super mouseUp: theEvent];
	NSPoint point = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	NSInteger row = [self rowAtPoint:point];
	MFFilesystemCell* cell = (MFFilesystemCell*)[self preparedCellAtColumn:0 row:row];
	
	if (NSPointInRect( point , [self rectOfRow: mountPushedRow] ) && [cell mountButtonEnabled])
	{
		[self.controller toggleMountOnFilesystem: [filesystems objectAtIndex: mountPushedRow] ];
	}
	if (NSPointInRect( point, [self rectOfRow: editPushedRow] ) && [cell editButtonEnabled])
	{
		[self.controller editFilesystem: [filesystems objectAtIndex: editPushedRow] ];
	}
	
	if (editPushedRow != NSNotFound)
	{
		NSInteger temp = editPushedRow;
		editPushedRow = NSNotFound;
		[self setNeedsDisplayInRect: [self rectOfRow: temp]];
	}
	if (mountPushedRow != NSNotFound)
	{
		NSInteger temp = mountPushedRow;
		mountPushedRow = NSNotFound;
		[self setNeedsDisplayInRect: [self rectOfRow: temp]];
	}

	[self setNeedsDisplayInRect: [self rectOfRow: row]];

}

- (void)keyDown:(NSEvent*)event
{
//	MFLogS(self, @"keyDown %@", event);
	if ([self selectedRow] ==  NSNotFound)
	{
		[super keyDown: event];
		return;
	}
	
	if (editPushedRow != NSNotFound || mountPushedRow != NSNotFound)
		return;
	
	MFFilesystemCell* cell = (MFFilesystemCell*)[self preparedCellAtColumn: 0 row: [self selectedRow]];
	
	if ([event keyCode] == 46 && [cell mountButtonEnabled])
	{
		mountPushedRow = [self selectedRow];
		[self setNeedsDisplayInRect: [self rectOfRow: [self selectedRow]]];
		return;
	}
	if ([event keyCode] == 14 && [cell editButtonEnabled])
	{
		editPushedRow = [self selectedRow];
		[self setNeedsDisplayInRect: [self rectOfRow: [self selectedRow]]];
		return;
	}
	if ([event keyCode] == 117)
	{
		[controller deleteFilesystem: [self.filesystems objectAtIndex: [self selectedRow]]];
		return;
	}
		
	[super keyDown: event];
}


- (void)keyUp:(NSEvent*)event
{
	MFFilesystemCell* cell = (MFFilesystemCell*)[self preparedCellAtColumn: 0 row: [self selectedRow]];
	//	MFLogS(self, @"keyUp %@ mountEnabled %d", event, [cell mountButtonEnabled]);
	if ([event keyCode] == 46 && [cell mountButtonEnabled] && mountPushedRow != NSNotFound)
	{
		NSUInteger oldRow = mountPushedRow;
		[controller toggleMountOnFilesystem: [self.filesystems objectAtIndex: mountPushedRow]];
		mountPushedRow = NSNotFound;
		[self setNeedsDisplayInRect: [self rectOfRow: oldRow]];
	}
	
	if ([event keyCode] == 14 && [cell editButtonEnabled])
	{
		[controller editFilesystem: [self.filesystems objectAtIndex: editPushedRow]];
		editPushedRow = NSNotFound;
	}
	
	[super keyUp:event];
}
 

# pragma mark D&D

- (BOOL)tableView:(NSTableView *)tableView
writeRowsWithIndexes:(NSIndexSet *)rowIndexes 
	 toPasteboard:(NSPasteboard*)pboard
{
	// MFLogS(self, @"Pasteboard writeRows called");
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
namesOfPromisedFilesDroppedAtDestination:(NSString*)dest
forDraggedRowsWithIndexes:(NSIndexSet*)indexes
{
	
	return nil;
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
 
@synthesize filesystems, controller;
@end
