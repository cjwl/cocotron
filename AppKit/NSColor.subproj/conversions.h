/* Copyright (c) 2006 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// NSColorHSBToRGB, NSColorRGBToHSB 
// Algorithms from "Computer Graphics Principles and Practice" by Foley, van Dam, Feiner, Hughes

static inline void NSColorHSBToRGB(float hue,float saturation,float brightness,float *redp,float *greenp,float *bluep) {
   float red=brightness,green=brightness,blue=brightness;

   if(saturation!=0){
    float frac,p,q,t;
    int   intHue;

    hue=hue*360;
    if(hue==360)
     hue=0;
    hue=hue/60;
    intHue=hue;
    frac=hue-intHue;

    p=brightness*(1.0-saturation);
    q=brightness*(1.0-(saturation*frac));
    t=brightness*(1.0-(saturation*(1.0-frac)));
    switch(intHue){
     case 0: red=brightness; green=t; blue=p; break;
     case 1: red=q; green=brightness; blue=p; break;
     case 2: red=p; green=brightness; blue=t; break;
     case 3: red=p; green=q; blue=brightness; break;
     case 4: red=t; green=p; blue=brightness; break;
     case 5: red=brightness; green=p; blue=q; break;
    }
   }

   *redp=red;
   *greenp=green;
   *bluep=blue;
}

static inline void NSColorRGBToHSB(float red,float green,float blue,float *huep,float *saturationp,float *brightnessp) {
   float hue=0,saturation=0,brightness,min,max;

   max=MAX(red,MAX(green,blue));
   min=MIN(red,MIN(green,blue));

   brightness=max;
   if(max>0){
    float delta=max-min;

    saturation=delta/max;
    if(red==max)
     hue=(green-blue)/delta;
    else if(green==max)
     hue=2+(blue-red)/delta;
    else if(blue==max)
     hue=4+(red-green)/delta;
    hue=hue*60;
    if(hue<0)
     hue=hue+360;
   }

   if(hue!=hue)
    hue=0;

   if(huep!=NULL)
    *huep=hue/360.0;
   if(saturationp!=NULL)
    *saturationp=saturation;
   if(brightnessp!=NULL)
    *brightnessp=brightness;
}
