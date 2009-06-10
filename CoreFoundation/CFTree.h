/* Copyright (c) 2008-2009 Christopher J. W. Lloyd

Permission is hereby granted,free of charge,to any person obtaining a copy of this software and associated documentation files (the "Software"),to deal in the Software without restriction,including without limitation the rights to use,copy,modify,merge,publish,distribute,sublicense,and/or sell copies of the Software,and to permit persons to whom the Software is furnished to do so,subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",WITHOUT WARRANTY OF ANY KIND,EXPRESS OR IMPLIED,INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,DAMAGES OR OTHER LIABILITY,WHETHER IN AN ACTION OF CONTRACT,TORT OR OTHERWISE,ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <CoreFoundation/CFBase.h>


typedef struct CFTree *CFTreeRef;

typedef CFAllocatorRetainCallBack          CFTreeRetainCallBack;
typedef CFAllocatorReleaseCallBack         CFTreeReleaseCallBack;
typedef CFAllocatorCopyDescriptionCallBack CFTreeCopyDescriptionCallBack;

typedef struct {
   CFIndex                       version;
   void                         *info;
   CFTreeRetainCallBack          retain;
   CFTreeReleaseCallBack         release;
   CFTreeCopyDescriptionCallBack copyDescription;
} CFTreeContext;

typedef void (*CFTreeApplierFunction)(const void *value,void *context);

CFTypeID  CFTreeGetTypeID(void);

CFTreeRef CFTreeCreate(CFAllocatorRef allocator,const CFTreeContext *context);

void      CFTreeGetContext(CFTreeRef self,CFTreeContext *context);

void      CFTreeAppendChild(CFTreeRef self,CFTreeRef child);
void      CFTreeApplyFunctionToChildren(CFTreeRef self,CFTreeApplierFunction function,void *context);
CFTreeRef CFTreeFindRoot(CFTreeRef self);
CFTreeRef CFTreeGetChildAtIndex(CFTreeRef self,CFIndex index);
CFIndex   CFTreeGetChildCount(CFTreeRef self);
void      CFTreeGetChildren(CFTreeRef self,CFTreeRef *children);
CFTreeRef CFTreeGetFirstChild(CFTreeRef self);
CFTreeRef CFTreeGetNextSibling(CFTreeRef self);
CFTreeRef CFTreeGetParent(CFTreeRef self);
void      CFTreeInsertSibling(CFTreeRef self,CFTreeRef sibling);
void      CFTreePrependChild(CFTreeRef self,CFTreeRef child);
void      CFTreeRemove(CFTreeRef self);
void      CFTreeRemoveAllChildren(CFTreeRef self);
void      CFTreeSetContext(CFTreeRef self,const CFTreeContext *context);
void      CFTreeSortChildren(CFTreeRef self,CFComparatorFunction function,void *context);
