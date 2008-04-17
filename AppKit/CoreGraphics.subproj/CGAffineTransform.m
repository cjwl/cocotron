/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import <ApplicationServices/CGAffineTransform.h>

const CGAffineTransform CGAffineTransformIdentity={1,0,0,1,0,0};

CGAffineTransform CGAffineTransformMake(float a,float b,float c,float d,float tx,float ty){
   CGAffineTransform xform={a,b,c,d,tx,ty};
   return xform;
}

CGAffineTransform CGAffineTransformMakeRotation(float radians){
   CGAffineTransform xform={cos(radians),sin(radians),-sin(radians),cos(radians),0,0};
   return xform;
}

CGAffineTransform CGAffineTransformMakeScale(float scalex,float scaley){
   CGAffineTransform xform={scalex,0,0,scaley,0,0};
   return xform;
}

CGAffineTransform CGAffineTransformMakeTranslation(float tx,float ty){
   CGAffineTransform xform={1,0,0,1,tx,ty};
   return xform;
}

CGAffineTransform CGAffineTransformConcat(CGAffineTransform xform,CGAffineTransform append){
   CGAffineTransform result;

   result.a=append.a*xform.a+append.b*xform.c;
   result.b=append.a*xform.b+append.b*xform.d;
   result.c=append.c*xform.a+append.d*xform.c;
   result.d=append.c*xform.b+append.d*xform.d;
   result.tx=append.tx*xform.a+append.ty*xform.c+xform.tx;
   result.ty=append.tx*xform.b+append.ty*xform.d+xform.ty;

   return result;
}

CGAffineTransform CGAffineTransformInvert(CGAffineTransform xform){
   CGAffineTransform result;
   float determinant;

   determinant=xform.a*xform.d-xform.c*xform.b;
   if(determinant==0)
    return xform;

   result.a=xform.d/determinant;
   result.b=-xform.b/determinant;
   result.c=-xform.c/determinant;
   result.d=xform.a/determinant;
   result.tx=(-xform.d*xform.tx+xform.c*xform.ty)/determinant;
   result.ty=(xform.b*xform.tx-xform.a*xform.ty)/determinant;

   return result;
}

CGAffineTransform CGAffineTransformRotate(CGAffineTransform xform,float radians){
   CGAffineTransform rotate=CGAffineTransformMakeRotation(radians);
   return CGAffineTransformConcat(xform,rotate);
}

CGAffineTransform CGAffineTransformScale(CGAffineTransform xform,float scalex,float scaley){
   CGAffineTransform scale=CGAffineTransformMakeScale(scalex,scaley);
   return CGAffineTransformConcat(xform,scale);
}

CGAffineTransform CGAffineTransformTranslate(CGAffineTransform xform,float tx,float ty){
   CGAffineTransform translate=CGAffineTransformMakeTranslation(tx,ty);
   return CGAffineTransformConcat(xform,translate);
}

CGPoint CGPointApplyAffineTransform(CGPoint point,CGAffineTransform xform){
    CGPoint p;

    p.x=xform.a*point.x+xform.c*point.y+xform.tx;
    p.y=xform.b*point.x+xform.d*point.y+xform.ty;

    return p;
}

CGSize CGSizeApplyAffineTransform(CGSize size,CGAffineTransform xform){
    CGSize s;

    s.width=xform.a*size.width+xform.c*size.height;
    s.height=xform.b*size.width+xform.d*size.height;

    return s;
}
