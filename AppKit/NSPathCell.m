#import <AppKit/NSPathCell.h>

#import <AppKit/NSPathComponentCell.h>
#import <AppKit/AppKit.h>

#import "AppKit/NSRaise.h"

@implementation NSPathCell

- initWithCoder: (NSCoder *) coder;
{
	self = [super initWithCoder: coder];
	if (self) {
		if (![coder allowsKeyedCoding]) {
			[NSException raise:NSInvalidArgumentException format:@"%@ can not initWithCoder:%@",isa,[coder class]];
		}
		
		NSKeyedUnarchiver *keyed = (NSKeyedUnarchiver *)coder;
		
		[self setPlaceholderString: [keyed decodeObjectForKey: @"NSPlaceholderString"]];
		[self setBackgroundColor: [keyed decodeObjectForKey: @"NSBackgroundColor"]];
		[self setPathComponentCells: [keyed decodeObjectForKey: @"NSPathComponentCells"]];
		[self setPathStyle: [keyed decodeIntForKey: @"NSPathStyle"]];
		[self setDelegate: [keyed decodeObjectForKey: @"NSDelegate"]];
		[self setAllowedTypes: [keyed decodeObjectForKey: @"NSAllowedTypes"]];
	}
	
	return self;
}

- (void)mouseEntered:(NSEvent *)event withFrame:(NSRect)frame inView:(NSView *)view;
{
	NSUnimplementedMethod();
}

- (void)mouseExited:(NSEvent *)event withFrame:(NSRect)frame inView:(NSView *)view;
{
	NSUnimplementedMethod();
}

- (NSArray *)allowedTypes;
{
	return [[_allowedTypes retain] autorelease];
}

- (void)setAllowedTypes:(NSArray *)allowedTypes;
{
	if (allowedTypes != _allowedTypes) {
		[_allowedTypes release];
		_allowedTypes = [allowedTypes copy];
	}
}

- (NSPathStyle)pathStyle;
{
	return _pathStyle;
}

- (void)setPathStyle:(NSPathStyle)style;
{
	if (_pathStyle != style) {
		_pathStyle = style;
		[[self controlView] setNeedsDisplay: YES];
	}
}

- (id) objectValue;
{
	return [self URL];
}

- (void)setObjectValue:(id <NSCopying>)newObj;
{
	id obj = newObj;
	NSAssert( [obj isKindOfClass: [NSURL class]] || [obj isKindOfClass: [NSString class]], @"NSPathCell accepts URLs or strings as path" );
	if ([obj isKindOfClass: [NSURL class]]) [self setURL: obj];
	else [self setURL: [NSURL fileURLWithPath: obj]];
}

- (NSAttributedString *)placeholderAttributedString;
{
	return [[_placeholder retain] autorelease];
}

- (void)setPlaceholderAttributedString:(NSAttributedString *)string;
{
	if (_placeholder != string) {
		[_placeholder release];
		_placeholder = [string copy];
	}
}

- (NSString *)placeholderString;
{
	return [_placeholder string];
}

- (void)setPlaceholderString:(NSString *)string;
{
	[self setPlaceholderAttributedString: [[[NSAttributedString alloc] initWithString: string] autorelease]];
}

- (NSColor *)backgroundColor;
{
	return [[_backgroundColor retain] autorelease];
}

- (void)setBackgroundColor:(NSColor *)color;
{
	if (_backgroundColor != color) {
		[_backgroundColor release];
		_backgroundColor = [color copy];
	}
}

+ (Class)pathComponentCellClass;
{
	return [NSPathComponentCell class];
}

- (NSRect)rectOfPathComponentCell:(NSPathComponentCell *)cell withFrame:(NSRect)frame inView:(NSView *)view;
{
	NSRect rect = frame;

	for (NSPathComponentCell *currentCell in _pathComponentCells) {
		rect.size.width = [currentCell cellSize].width;
		if (cell == currentCell) return rect;
		rect.origin.x += rect.size.width + 5;
	}
	
	return NSZeroRect;
}

- (NSPathComponentCell *)pathComponentCellAtPoint:(NSPoint)point withFrame:(NSRect)frame inView:(NSView *)view;
{
	for (NSPathComponentCell *cell in _pathComponentCells) {
		NSRect cellFrame = [self rectOfPathComponentCell: cell withFrame: frame inView: view];
		if (NSPointInRect( point, cellFrame )) return cell;
	}
	return nil;
}

- (NSPathComponentCell *)clickedPathComponentCell;
{
	NSUnimplementedMethod();
	return nil;
}

- (NSArray *)pathComponentCells;
{
	return [[_pathComponentCells retain] autorelease];
}

- (void)setPathComponentCells:(NSArray *)cells;
{
	if (_pathComponentCells != cells) {
		[_pathComponentCells release];
		_pathComponentCells = [cells retain];
		[[self controlView] setNeedsDisplay: YES];
	}
}

- (SEL)doubleAction;
{
	return _doubleAction;
}

- (void)setDoubleAction:(SEL)action;
{
	_doubleAction = action;
}

- (NSURL *)URL;
{
	return [[_URL retain] autorelease];
}

- (void)setURL:(NSURL *)url;
{
	if (url != _URL) {
		[_URL release];
		_URL = [url copy];
		
		NSMutableArray *cells = nil;
		if (url) {
			NSString *host = [url host];
			NSString *path = [url path];
			NSString *scheme = [url scheme];
			
			NSArray *pathComponents = [path pathComponents];
			
			cells = [NSMutableArray arrayWithCapacity: [pathComponents count]];
			
			BOOL isFileURL = [url isFileURL];
			NSFileManager *fm = nil;
			NSWorkspace *ws = nil;
			if (isFileURL) {
				fm = [NSFileManager defaultManager];
				ws = [NSWorkspace sharedWorkspace];
			}
			
			NSMutableString *currentPath = [NSMutableString stringWithCapacity: [path length]];
			[currentPath appendString: @"/"];
			
			Class pcClass = [[self class] pathComponentCellClass];
			
			for (NSString *path in pathComponents) {
				[currentPath appendString: path];
				NSURL *currentUrl = [[[NSURL alloc] initWithScheme: scheme host: host path: currentPath] autorelease];

				NSString *title = path;
				NSImage *image = nil;
				
				if (isFileURL) {
					NSString *currentPath = [currentUrl path];
					title = [fm displayNameAtPath: currentPath]; 
					image = [ws iconForFile: currentPath];
				}
				
				NSPathComponentCell *cell = [[[pcClass alloc] initTextCell: nil] autorelease];
				[cell setURL: currentUrl];
				[cell setImage: image];
				[cell setStringValue: title];
				
				[cells addObject: cell];
				
				[currentPath appendString: @"/"];
			}
		}

		[self setPathComponentCells: cells];
	}
}

- (id)delegate;
{
	return _delegate;
}

- (void)setDelegate:(id)delegate;
{
	_delegate = delegate;
}

- (void) dealloc;
{
	[self setAllowedTypes: nil];
	[self setURL: nil];
	[self setBackgroundColor: nil];

	[super dealloc];
}


- (void) drawInteriorWithFrame:(NSRect)frame inView:(NSView *)view;
{
	[_backgroundColor set];
	[NSBezierPath fillRect: frame];
	
	for (NSPathComponentCell *cell in _pathComponentCells) {
		NSRect cellFrame = [self rectOfPathComponentCell: cell withFrame: frame inView: view];
		[cell drawInteriorWithFrame: cellFrame inView: view];
	}
}

@end