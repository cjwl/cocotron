/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <AppKit/NSTextContainer.h>
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSTextView.h>
#import <Foundation/NSKeyedArchiver.h>
#import <AppKit/NSRaise.h>

@implementation NSTextContainer

-initWithCoder:(NSCoder *)coder {
   if([coder allowsKeyedCoding]){
    NSKeyedUnarchiver *keyed=(NSKeyedUnarchiver *)coder;
    
    _size.width=[keyed decodeFloatForKey:@"NSWidth"];
    _size.height=0;
    _textView=[keyed decodeObjectForKey:@"NSTextView"];
    _layoutManager=[keyed decodeObjectForKey:@"NSLayoutManager"];
    _size.height=[_textView frame].size.height;
    _lineFragmentPadding=0;
    _widthTracksTextView=YES;
    _heightTracksTextView=YES;
   }
   else {
    [NSException raise:NSInvalidArgumentException format:@"-[%@ %s] is not implemented for coder %@",isa,sel_getName(_cmd),coder];
   }
   return self;
}

-initWithContainerSize:(NSSize)size {
   _size=size;
   _textView=nil;
   _layoutManager=nil;
   _lineFragmentPadding=0;
   _widthTracksTextView=YES;
   _heightTracksTextView=YES;
   return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
-(NSSize)containerSize {
   return _size;
}

-(NSTextView *)textView {
   return _textView;
}

-(BOOL)widthTracksTextView {
   return _widthTracksTextView;
}

-(BOOL)heightTracksTextView {
   return _heightTracksTextView;
}

-(NSLayoutManager *)layoutManager {
   return _layoutManager;
}

-(float)lineFragmentPadding {
   return _lineFragmentPadding;
}

-(void)setContainerSize:(NSSize)size {
   if(!NSEqualSizes(_size,size)){
    _size=size;
    [_layoutManager textContainerChangedGeometry:self];
   }
}

-(void)setTextView:(NSTextView *)textView {
    _textView = textView;
    [_textView setTextContainer:self];
}

-(void)_textViewFrameDidChange:(NSNotification *)notification
{
	if ([notification object] == _textView) {
		NSSize newSize = [_textView frame].size;
		[self setContainerSize:newSize];
	}
}

-(void)setWidthTracksTextView:(BOOL)flag {
	if (flag != _widthTracksTextView) {
		_widthTracksTextView=flag;
		if (_textView) {
			if (_widthTracksTextView) {
				if (_heightTracksTextView == NO) {
					// Observe our textView frame changes
					[_textView setPostsFrameChangedNotifications:YES];
					[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_textViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:_textView];
				}
			} else {
				if (_heightTracksTextView == NO) {
					[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_textView];
				}
			}
		}
	}
}

-(void)setHeightTracksTextView:(BOOL)flag {
	if (flag != _heightTracksTextView) {
		_heightTracksTextView=flag;
		if (_textView) {
			if (_heightTracksTextView) {
				if (_widthTracksTextView == NO) {
					// Observe our textView frame changes
					[_textView setPostsFrameChangedNotifications:YES];
					[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_textViewFrameDidChange:) name:NSViewFrameDidChangeNotification object:_textView];
				}
			} else {
				if (_widthTracksTextView == NO) {
					[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:_textView];
				}
			}
		}
	}	
}

-(void)setLayoutManager:(NSLayoutManager *)layoutManager {
   _layoutManager=layoutManager;
}

-(void)replaceLayoutManager:(NSLayoutManager *)layoutManager {
   _layoutManager=layoutManager;
}

-(void)setLineFragmentPadding:(float)padding {
   _lineFragmentPadding=padding;
}

-(BOOL)isSimpleRectangularTextContainer {
   return YES;
}

-(BOOL)containsPoint:(NSPoint)point {
   return NSPointInRect(point,NSMakeRect(0,0,_size.width,_size.height));
}

-(NSRect)lineFragmentRectForProposedRect:(NSRect)proposed sweepDirection:(NSLineSweepDirection)sweep movementDirection:(NSLineMovementDirection)movement remainingRect:(NSRectPointer)remaining {
   NSRect result=proposed;

   if(sweep!=NSLineSweepRight || movement!=NSLineMovesDown)
    NSUnimplementedMethod();

   if(result.origin.x+result.size.width>_size.width)
    result.size.width=_size.width-result.origin.x;

   if(result.size.width<=0)
    result=NSZeroRect;

   *remaining=NSZeroRect;

   return result;
}

@end
