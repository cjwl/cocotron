/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <AppKit/NSController.h>

@class NSPredicate,NSFetchRequest,NSManagedObjectContext,NSMenuItem,NSError,NSArray;

@interface NSObjectController : NSController {

}

#if 0
-initWithContent:content;

-content;
-(Class)objectClass;
-(NSString *)entityName;
-(NSPredicate *)fetchPredicate;
-(NSManagedObjectContext *)managedObjectContext;
-(BOOL)isEditable;
-(BOOL)automaticallyPreparesContent;

-(void)setContent:content;
-(void)setObjectClass:(Class)class;
-(void)setEntityName:(NSString *)name;
-(void)setFetchPredicate:(NSPredicate *)predicate;
-(void)setManagedObjectContext:(NSManagedObjectContext *)context;
-(void)setEditable:(BOOL)flag;
-(void)setAutomaticallyPreparesContent:(BOOL)flag;

-(void)addObject:object;

-selection;
-(NSArray *)selectedObjects;

-newObject;

-(BOOL)canAdd;
-(BOOL)canRemove;
-(void)add:sender;
-(void)fetch:sender;
-(void)remove:sender;
-(void)removeObject:object;

-(void)prepareContent;

-(BOOL)fetchWithRequest:(NSFetchRequest *)fetchRequest merge:(BOOL)merge error:(NSError **)error;

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem;
#endif

@end
