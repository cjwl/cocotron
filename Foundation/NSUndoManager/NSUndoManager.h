/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>

@class NSArray, NSMutableArray, NSInvocation;

FOUNDATION_EXPORT const unsigned NSUndoCloseGroupingRunLoopOrdering;

FOUNDATION_EXPORT NSString *NSUndoManagerCheckpointNotification;

FOUNDATION_EXPORT NSString *NSUndoManagerDidOpenUndoGroupNotification;
FOUNDATION_EXPORT NSString *NSUndoManagerWillCloseUndoGroupNotification;

FOUNDATION_EXPORT NSString *NSUndoManagerWillUndoChangeNotification;
FOUNDATION_EXPORT NSString *NSUndoManagerDidUndoChangeNotification;

FOUNDATION_EXPORT NSString *NSUndoManagerWillRedoChangeNotification;
FOUNDATION_EXPORT NSString *NSUndoManagerDidRedoChangeNotification;


@interface NSUndoManager : NSObject {
    NSMutableArray *_undoStack;
    NSMutableArray *_redoStack;
    BOOL _groupsByEvent;
    NSArray *_modes;
    int _disableCount;
    int _levelsOfUndo;
    id _currentGroup;
    int _state;
    NSString *_actionName;
    id _preparedTarget;
    BOOL _performRegistered;
}

-(NSArray *)runLoopModes;
-(unsigned)levelsOfUndo;
-(BOOL)groupsByEvent;

-(void)setRunLoopModes:(NSArray *)modes;
-(void)setLevelsOfUndo:(unsigned)levels;
-(void)setGroupsByEvent:(BOOL)flag;

-(BOOL)isUndoRegistrationEnabled;
-(void)disableUndoRegistration;
-(void)enableUndoRegistration;

-(void)beginUndoGrouping;
-(void)endUndoGrouping;

-(int)groupingLevel;

-(BOOL)canUndo;
-(void)undo;
-(void)undoNestedGroup;
-(BOOL)isUndoing;

-(BOOL)canRedo;
-(void)redo;
-(BOOL)isRedoing;

-(void)registerUndoWithTarget:(id)target selector:(SEL)selector object:(id)object;

-(void)removeAllActions;
-(void)removeAllActionsWithTarget:(id)target;

-(id)prepareWithInvocationTarget:(id)target;
-(void)forwardInvocation:(NSInvocation *)invocation;

-(NSString *)undoActionName;
-(NSString *)undoMenuItemTitle;
-(NSString *)undoMenuTitleForUndoActionName:(NSString *)name;
-(void)setActionName:(NSString *)name;

-(NSString *)redoActionName;
-(NSString *)redoMenuItemTitle;
-(NSString *)redoMenuTitleForUndoActionName:(NSString *)name;

@end

