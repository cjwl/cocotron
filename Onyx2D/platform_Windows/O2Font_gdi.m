#import <Onyx2D/O2Font_gdi.h>
#import <windows.h>
#import <Foundation/NSString_win32.h>
#import "Win32Font.h"
#import <Onyx2D/O2Encoding.h>
#import <Onyx2D/O2Font_freetype.h>
#include <CoreFoundation/CoreFoundation.h>

O2FontRef O2FontCreateWithFontName_platform(NSString *name) {
   return [[O2Font_gdi alloc] initWithFontName:name];
}

O2FontRef O2FontCreateWithDataProvider_platform(O2DataProviderRef provider) {
#ifdef FREETYPE_PRESENT
   return [[O2Font_freetype alloc] initWithDataProvider:provider];
#else
   return nil;
#endif

}

@implementation O2Font(GDI)
static NSMutableDictionary *sPSToWin32Table = nil;
static NSMutableDictionary *sWin32ToPSTable = nil;

// Some struct to help to parse the font name tables
// see http://developer.apple.com/fonts/ttrefman/rm06/Chap6name.html
typedef struct name_table_header_t {
	uint16_t	format;
	uint16_t	count;
	uint16_t	stringOffset;
} name_table_header_t;

typedef struct name_records_t {
	uint16_t	platformID;
	uint16_t	platformSpecificID;
	uint16_t	languageID;
	uint16_t	nameID;
	uint16_t	length;
	uint16_t	offset;
} name_records_t;

// Fill the name mapping dictionaries with the longFont face info
static int EnumFontFromFamilyCallBack(const EXTLOGFONTW* longFont,const TEXTMETRICW* metrics, DWORD ignored, HDC dc)
{
	HFONT font = CreateFontIndirectW(&longFont->elfLogFont);
	if (font) {
		SelectObject(dc, font);

		// Get the full face name
		NSString *winName = [NSString stringWithFormat:@"%S", longFont->elfFullName];

		// Get the PS name for the font...
		DWORD bufferSize = GetFontData(dc, CFSwapInt32HostToBig('name'), 0, NULL, 0);
		if (bufferSize >= 6 && bufferSize != GDI_ERROR) {
			uint8_t buffer[bufferSize];
			if (GetFontData(dc, CFSwapInt32HostToBig('name'), 0, buffer, bufferSize) != GDI_ERROR) {
				name_table_header_t *header = (name_table_header_t *)buffer;
				uint16_t count = CFSwapInt16BigToHost(header->count);
				uint16_t stringsOffset = CFSwapInt16BigToHost(header->stringOffset);
				if (bufferSize > stringsOffset) {
					uint8_t* strings = buffer + stringsOffset;
					name_records_t* nameRecords = (name_records_t *)(buffer + sizeof(name_table_header_t));
					// Parse all of the name records until we find some PS name there
					for (int i = 0; i < count; i++) {
						uint16_t platformID = CFSwapInt16BigToHost(nameRecords[i].platformID);
						uint16_t platformSpecificID = CFSwapInt16BigToHost(nameRecords[i].platformSpecificID);
						uint16_t languageID = CFSwapInt16BigToHost(nameRecords[i].languageID);
						uint16_t nameID = CFSwapInt16BigToHost(nameRecords[i].nameID);
						uint16_t length = CFSwapInt16BigToHost(nameRecords[i].length);
						uint16_t offset = CFSwapInt16BigToHost(nameRecords[i].offset);
						if (nameID == 6) {
							// First check we get a string that's in our buffer, in case of some corrupted font or font entry
							if (stringsOffset + offset + length <= bufferSize) {
								// Check for Win+Unicode encoding or Mac+Roman encoding
								// Other entries should be ignored (see http://www.microsoft.com/typography/otspec/name.htm )
								
								// That's a Postscript name record
								if (platformID == 3 && platformSpecificID == 1)  {
									// Win PS name - unicode encoding
									NSString *name = [[[NSString alloc] initWithBytes:strings + offset length:length encoding:NSUnicodeStringEncoding] autorelease];
									if ([name length]) {
										[sPSToWin32Table setObject:winName forKey:name];
										[sWin32ToPSTable setObject:name forKey:winName];
									}
									break;
								} else if (platformID == 1 && platformSpecificID == 0) {
									// Mac PS name - ASCII
									NSString *name = [NSString stringWithCString:strings + offset length:length];
									if ([name length]) {
										[sPSToWin32Table setObject:winName forKey:name];
										[sWin32ToPSTable setObject:name forKey:winName];
									}	
									break;
								}
							}
						}
					}
				}
			}
		}
		DeleteObject(font);
	}
	return 1;
}

// Add the longFont family to the list of known families
static int EnumFamiliesCallBack(const LOGFONTW* longFont,const TEXTMETRICW* metrics, DWORD ignored, LPARAM p)
{
	NSMutableArray *families = (NSMutableArray *)p;
	NSString *winName = [NSString stringWithFormat:@"%S", longFont->lfFaceName];
	[families addObject:winName];
	return 1;
}

+ (void)_buildNativePSmapping
{
	HDC dc=GetDC(NULL);
	sPSToWin32Table = [[NSMutableDictionary alloc] initWithCapacity:100];
	sWin32ToPSTable = [[NSMutableDictionary alloc] initWithCapacity:100];
	
	// Get a list of all of the families
	NSMutableArray *families = [NSMutableArray arrayWithCapacity:100];
	EnumFontFamiliesW(dc, (LPCWSTR)NULL, (FONTENUMPROCW)EnumFamiliesCallBack, (LPARAM)families); 
	for (NSString *familyName in families) {
		// Enum all of the faces for that family
		LOGFONTW logFont = { 0 };

		int length = MIN([familyName length], LF_FACESIZE);
		[familyName getCharacters: logFont.lfFaceName range: NSMakeRange(0, length)];
		
		logFont.lfCharSet = DEFAULT_CHARSET;
		logFont.lfPitchAndFamily = 0;
		EnumFontFamiliesExW(dc, &logFont, (FONTENUMPROCW)EnumFontFromFamilyCallBack, (LPARAM)dc, 0); 
	}
	ReleaseDC(NULL,dc);
}



+ (NSString *)nativeFontNameForPostscriptName:(NSString *)psName
{
	NSString *name = psName;
	@synchronized(self) {
		if (sPSToWin32Table == nil) {
			[self _buildNativePSmapping];
		}
		name = [sPSToWin32Table objectForKey:psName];
		if (name == nil) {
			name = psName;
		}
	}
	return name;
}

+ (NSString *)postscriptNameForNativeName:(NSString *)nativeName
{
	NSString *name = nativeName;
	@synchronized(self) {
		if (sWin32ToPSTable == nil) {
			[self _buildNativePSmapping];
		}
		name = [sWin32ToPSTable objectForKey:nativeName];
		if (name == nil) {
			name = nativeName;
		}
	}
	return name;	
}

+ (NSString *)postscriptNameForDisplayName:(NSString *)name
{
	// For now, we're using the Win32 name as the display name
	return [self postscriptNameForNativeName:name];
}

+ (NSString *)displayNameForPostscriptName:(NSString *)name
{
	// For now, we're using the Win32 name as the display name
	return [self nativeFontNameForPostscriptName:name];
}
@end


@interface O2Font_gdi(forward)
-(void)fetchGlyphsToCharacters;
@end

@implementation O2Font_gdi

static HFONT Win32FontHandleWithName(NSString *name,int unitsPerEm){
   const unichar *wideName=(const unichar *)[name cStringUsingEncoding:NSUnicodeStringEncoding];
   return CreateFontW(-unitsPerEm,0,0,0,FW_NORMAL,FALSE,FALSE,FALSE,DEFAULT_CHARSET,OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,DEFAULT_QUALITY,DEFAULT_PITCH|FF_DONTCARE,wideName);
}

-initWithFontName:(NSString *)name {
   if(name==nil){
    [self release];
    return nil;
   }
	
	name = [O2Font nativeFontNameForPostscriptName:name];
	_name=[name copy];
	
   _platformType=O2FontPlatformTypeGDI;

   HDC dc=GetDC(NULL);

   if(dc==NULL){
    [self release];
    return nil;
   }
   
// P. 931 "Windows Graphics Programming" by Feng Yuan, 1st Ed. A font with height of negative otmEMSquare will have precise metrics
// 2048 is a common TrueType em square, so we try that first, and if the font is not TrueType, maybe we'll get some decent metrics with a big size.
   _unitsPerEm=2048;
   
   HFONT           font=Win32FontHandleWithName(name,_unitsPerEm);
   TEXTMETRIC      gdiMetrics;

   if(font==NULL){
    ReleaseDC(NULL,dc);
    [self release];
    return nil;
   }
	
	SelectObject(dc,font);

	unichar wideName[128];
	GetTextFaceW(dc, 128, wideName);
	NSString *textFace = [NSString stringWithFormat:@"%S", wideName];
	if (![textFace isEqualToString:name]) {
		// That's not the expected font - let's fail
		DeleteObject(font);
		ReleaseDC(NULL,dc);
		[self release];
		return nil;
	}
	
   GetTextMetrics(dc,&gdiMetrics);
	
// default values if not truetype or truetype queries fail
   _ascent=gdiMetrics.tmAscent;
   _descent=-gdiMetrics.tmDescent;
   _leading=gdiMetrics.tmInternalLeading+gdiMetrics.tmExternalLeading;
   _capHeight=gdiMetrics.tmHeight;
   _xHeight=gdiMetrics.tmHeight;
   _italicAngle=0;
   _stemV=0;
   _bbox.origin.x=0;
   _bbox.origin.y=0;
   _bbox.size.width=gdiMetrics.tmMaxCharWidth;
   _bbox.size.height=gdiMetrics.tmHeight;
   
   if(gdiMetrics.tmPitchAndFamily&TMPF_TRUETYPE){
    int                 size=GetOutlineTextMetricsW(dc,0,NULL);
    OUTLINETEXTMETRICW *ttMetrics=__builtin_alloca(size);

    ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICW);
    if((size=GetOutlineTextMetricsW(dc,size,ttMetrics))!=0){
   
     if(ttMetrics->otmEMSquare!=_unitsPerEm){
      // if our first try didn't have the typical em square, recreate using the em square 
      LOGFONT logFont;
      
      GetObject(font,sizeof(logFont),&logFont);
      logFont.lfHeight=-ttMetrics->otmEMSquare;
      logFont.lfWidth=0;
     
      HFONT emSquareFont=CreateFontIndirect(&logFont);
      SelectObject(dc,emSquareFont);
      DeleteObject(font);
      font=emSquareFont;

      ttMetrics->otmSize=sizeof(OUTLINETEXTMETRICW);
      size=GetOutlineTextMetricsW(dc,size,ttMetrics);
     }
      
     if(size!=0){
      _unitsPerEm=ttMetrics->otmEMSquare;
      
	  // Don't use the magic pointSize scaling formula on these font (UI fonts) 
      if([name isEqualToString:@"Marlett"] || [name isEqualToString:@"Segoe UI"] || [name isEqualToString:@"Tahoma"]){
       _useMacMetrics=NO;
       _ascent=ttMetrics->otmAscent;
       _descent=ttMetrics->otmDescent;
       _leading=ttMetrics->otmLineGap;
      }
      else {
       _useMacMetrics=YES;
       _ascent=ttMetrics->otmMacAscent;
       _descent=ttMetrics->otmMacDescent;
       _leading=ttMetrics->otmMacLineGap;
      }
      
      _capHeight=ttMetrics->otmsCapEmHeight;
      _xHeight=ttMetrics->otmsXHeight;
      _italicAngle=ttMetrics->otmItalicAngle;
      _stemV=0;
      _bbox.origin.x=ttMetrics->otmrcFontBox.left;
      _bbox.origin.y=ttMetrics->otmrcFontBox.bottom;
      _bbox.size.width=ttMetrics->otmrcFontBox.right-ttMetrics->otmrcFontBox.left;
      _bbox.size.height=ttMetrics->otmrcFontBox.top-ttMetrics->otmrcFontBox.bottom;
     }
    }
   }
   
   DeleteObject(font);
   ReleaseDC(NULL,dc);
   
   return self;
}

-initWithDataProvider:(O2DataProviderRef)provider {
   if([super initWithDataProvider:provider]==nil)
    return nil;

   const void *bytes=[provider bytes];
   DWORD       length=[provider length];
   DWORD       numberOfFonts=1;

   _fontMemResource=AddFontMemResourceEx((PVOID)bytes,length,0,&numberOfFonts);
   NSLog(@"FAILURE AddFontMemResourceEx bytes=%p length=%d numberOfFonts=%d,result=%x",bytes,length,numberOfFonts,_fontMemResource);

   return self;
}

-(void)dealloc {
   if(_glyphsToCharacters!=NULL)
    NSZoneFree(NULL,_glyphsToCharacters);
   
   if(_fontMemResource!=NULL)
    if(!RemoveFontMemResourceEx(_fontMemResource))
     NSLog(@"RemoveFontMemResourceEx failed!");
   
   [_macRomanEncoding release];
   [_macExpertEncoding release];
   [_winAnsiEncoding release];
   [super dealloc];
}

-(O2Glyph)glyphWithGlyphName:(NSString *)name {
   NSLog(@"glyphWithGlyphName:%@",name);

   return 0;
}

-(NSString *)copyGlyphNameForGlyph:(O2Glyph)glyph {
   return nil;
}

-(NSData *)copyTableForTag:(uint32_t)tag {
   return nil;
}

-(void)fetchAdvances {
   [self fetchGlyphsToCharacters];
   
   HANDLE   library=LoadLibrary("GDI32");
   FARPROC  getGlyphIndices=GetProcAddress(library,"GetGlyphIndicesW");
   HDC      dc=GetDC(NULL);
   unichar  characters[65536];
   uint16_t glyphs[65536];
   int      i,max;
   ABCFLOAT *abc;
   
   for(i=0;i<65536;i++)
    characters[i]=i;
    
   HFONT font=Win32FontHandleWithName(_name,_unitsPerEm);
   SelectObject(dc,font);

   getGlyphIndices(dc,characters,65535,glyphs,0);

   _advances=NSZoneMalloc(NULL,sizeof(int)*_numberOfGlyphs);
   max=65535;
   max=((max/128)+1)*128;
   abc=__builtin_alloca(sizeof(ABCFLOAT)*max);
   if(!GetCharABCWidthsFloatW(dc,0,max-1,abc))
    NSLog(@"GetCharABCWidthsFloat failed");
   else {
    for(i=max;--i>=0;){
     O2Glyph glyph=glyphs[i];
     
     if(glyph<_numberOfGlyphs)
      _advances[glyph]=abc[i].abcfA+abc[i].abcfB+abc[i].abcfC;
    }
   }
   
   DeleteObject(font);
   ReleaseDC(NULL,dc);
}

-(Win32Font *)createGDIFontSelectedInDC:(HDC)dc pointSize:(CGFloat)pointSize {
	return [self createGDIFontSelectedInDC:dc pointSize:pointSize angle:0.];
}

-(Win32Font *)createGDIFontSelectedInDC:(HDC)dc pointSize:(CGFloat)pointSize angle:(CGFloat)angle {
   if(_useMacMetrics){
    if (pointSize <= 10.0)
       pointSize=pointSize;
    else if (pointSize < 20.0)
       pointSize=pointSize/(1.0 + 0.2*sqrtf(0.0390625*(pointSize - 10.0)));
    else
       pointSize=pointSize/1.125;
   }
   int        height=(pointSize*GetDeviceCaps(dc,LOGPIXELSY))/72.0;
	Win32Font *result=[[Win32Font alloc] initWithName:_name height:height antialias:YES angle: angle];
   
   SelectObject(dc,[result fontHandle]);
   
   return result;
}

// These are only used for PDF generation until we get PS glyph names working
// They are both temporary and inaccurate 

-(void)fetchGlyphsToCharacters {
   HDC      dc=GetDC(NULL);
   unichar  characters[65536];
   uint16_t glyphs[65536];
   int      i,maxGlyph=0;
   HANDLE   library=LoadLibrary("GDI32");
   FARPROC  getGlyphIndices=GetProcAddress(library,"GetGlyphIndicesW");

   for(i=0;i<65536;i++)
    characters[i]=i;
    
   HFONT font=Win32FontHandleWithName(_name,_unitsPerEm);
   SelectObject(dc,font);
   getGlyphIndices(dc,characters,65535,glyphs,0);
   DeleteObject(font);
   ReleaseDC(NULL,dc);
   
   for(i=0;i<65536;i++)
    maxGlyph=MAX(maxGlyph,glyphs[i]);
   _numberOfGlyphs=maxGlyph+1;

   _glyphsToCharacters=NSZoneMalloc(NULL,sizeof(unichar)*_numberOfGlyphs);
   for(i=65536;--i>=0;){
    if(glyphs[i]<_numberOfGlyphs)
     _glyphsToCharacters[glyphs[i]]=characters[i];
   }
}

-(void)getMacRomanBytes:(unsigned char *)bytes forGlyphs:(const O2Glyph *)glyphs length:(unsigned)length {
// FIXME: broken

   if(_glyphsToCharacters==NULL)
    [self fetchGlyphsToCharacters];

   int i;
   
   for(i=0;i<length;i++){
    if(glyphs[i]<_numberOfGlyphs){
     unichar code=_glyphsToCharacters[glyphs[i]];
     
     if(code<256)
      bytes[i]=code;
     else
      bytes[i]=' ';
    }
    else
     bytes[i]=' ';
   }
}

-(void)getGlyphsForUnicode:(unichar *)unicode:(O2Glyph *)glyphs:(int)length {
    HDC      dc=GetDC(NULL);
    HANDLE   library=LoadLibrary("GDI32");
    FARPROC  getGlyphIndices=GetProcAddress(library,"GetGlyphIndicesW");
    int      i;
       
    HFONT font=Win32FontHandleWithName(_name,_unitsPerEm);
    SelectObject(dc,font);
    getGlyphIndices(dc,unicode,256,glyphs,0);
    DeleteObject(font);
    ReleaseDC(NULL,dc);
}

-(O2Glyph *)MacRomanEncoding {
   if(_MacRomanEncoding==NULL){
    HDC      dc=GetDC(NULL);
    unichar  characters[256];
    HANDLE   library=LoadLibrary("GDI32");
    FARPROC  getGlyphIndices=GetProcAddress(library,"GetGlyphIndicesW");
    int      i;
   
    _MacRomanEncoding=NSZoneMalloc(NULL,sizeof(O2Glyph)*256);
    for(i=0;i<256;i++)
     characters[i]=i;
    
    HFONT font=Win32FontHandleWithName(_name,_unitsPerEm);
    SelectObject(dc,font);
    getGlyphIndices(dc,characters,256,_MacRomanEncoding,0);
    DeleteObject(font);
    ReleaseDC(NULL,dc);
   }
   return _MacRomanEncoding;
}

-(O2Encoding *)createEncodingForTextEncoding:(O2TextEncoding)encoding {
   unichar unicode[256];
   O2Glyph glyphs[256];
   
   switch(encoding){
    case kO2EncodingFontSpecific:
    case kO2EncodingMacRoman:
     if(_macRomanEncoding==nil){
      O2EncodingGetMacRomanUnicode(unicode);
      [self getGlyphsForUnicode:unicode:glyphs:256];
      _macRomanEncoding=[[O2Encoding alloc] initWithGlyphs:glyphs unicode:unicode];
     }
     return [_macRomanEncoding retain];
     
    case kO2EncodingMacExpert:
     if(_macExpertEncoding==nil){
      O2EncodingGetMacExpertUnicode(unicode);
      [self getGlyphsForUnicode:unicode:glyphs:256];
      _macExpertEncoding=[[O2Encoding alloc] initWithGlyphs:glyphs unicode:unicode];
     }
     return [_macExpertEncoding retain];

    case kO2EncodingWinAnsi:
     if(_winAnsiEncoding==nil){
      O2EncodingGetWinAnsiUnicode(unicode);
      [self getGlyphsForUnicode:unicode:glyphs:256];
      _winAnsiEncoding=[[O2Encoding alloc] initWithGlyphs:glyphs unicode:unicode];
     }
     return [_winAnsiEncoding retain];

    case kO2EncodingUnicode:
     break;
   }
   
   return nil;
}

@end
