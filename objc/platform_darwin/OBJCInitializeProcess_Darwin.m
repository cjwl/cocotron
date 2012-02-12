/* Copyright (c) 2007 Matteo Ceruti (matteo@ceruti.org)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */


#import "ObjCModule.h"
#import <objc/objc-class.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import "objc_sel.h"
#import "objc_class.h"
#import <string.h>
#import "ObjCException.h"
#import <Foundation/NSRaiseException.h>

/*
 * Fetches all Objective-C-Modules via the mach-o/dyld.h interface and initializes them.
 */
void OBJCInitializeProcess_Darwin(void)
{
   int i;
   int count = _dyld_image_count();


   //Fix up sel references

   for (i = 0; i < count; i++) {
#ifdef __LP64__
      const struct mach_header_64 *head = (struct mach_header_64 *) _dyld_get_image_header(i);

      uint64_t size;
      char *section = getsectdatafromheader_64(head,"__OBJC", "__message_refs", &size);
#else
      const struct mach_header *head = _dyld_get_image_header(i);

      uint32_t size;
      char *section = getsectdatafromheader(head,"__OBJC", "__message_refs", &size);
#endif
      if(head->filetype == MH_DYLIB)
         section += _dyld_get_image_vmaddr_slide(i);

      long nmess = size / sizeof(SEL);

      SEL *sels = (SEL*)section;


      int j;
      for(j=0; j<nmess; j++)
      {
         sels[j] = sel_registerNameNoCopy((const char *) sels[j]);;
      }
   } //iterate mach_headers


   // queue each module.

   for (i = 0; i < count; i++) {
      long nmodules = 0;

      OBJCModule *mods = 0;
      char *section = 0;

#ifdef __LP64__
      const struct mach_header_64 *head = (struct mach_header_64 *)_dyld_get_image_header(i);

      uint64_t size=0;
      section = getsectdatafromheader_64(head,"__OBJC","__module_info",&size);
#else
      const struct mach_header *head = _dyld_get_image_header(i);

      uint32_t size=0;
      section = getsectdatafromheader(head,"__OBJC","__module_info",&size);
#endif
      if(head->filetype == MH_DYLIB)
         section += _dyld_get_image_vmaddr_slide(i);

      mods = (OBJCModule*)section;

      nmodules = size / sizeof(OBJCModule);

      long j;
      for(j=0; j<nmodules; j++)
      {
         OBJCModule *m = &mods[j];
         OBJCQueueModule(m);
      }
   }  //iterate mach_headers



   /*
   * Now all classes should have been seen. Now fix class references.
   */

   for (i = 0; i < count; i++) {
#ifdef __LP64__
      const struct mach_header_64 *head = (struct mach_header_64 *)_dyld_get_image_header(i);

      uint64_t size = 0;
      char *section  = getsectdatafromheader_64(head,"__OBJC", "__cls_refs", &size);
#else
      const struct mach_header *head = _dyld_get_image_header(i);

      uint32_t size = 0;
      char *section  = getsectdatafromheader (head,"__OBJC", "__cls_refs", &size);
#endif
      typeof(size) nrefs = size / sizeof(struct objc_class *);

      if(head->filetype == MH_DYLIB)
         section += _dyld_get_image_vmaddr_slide(i);

      Class *refs = (Class*)section;
      long j;
      for(j=0; j<nrefs; j++)
      {
          const char *aref = (const char*)refs[j]; // yes these are strings !

          Class c = objc_lookUpClass(aref);
          if(c)
          {
             refs[j] = c; //replace with actual Class
          }
          else
          {
            // when could this happen?
             NSCLog("%s does not exist yet!? Is it a ref?\n", aref );
          }
      }
   } //iterate mach_headers
}

