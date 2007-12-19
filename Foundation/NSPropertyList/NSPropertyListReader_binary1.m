/* Copyright (c) 2007 Michael Ash
   Copyright (c) 2007 Jens Ayton (uid decoding)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import "NSPropertyListReader_binary1.h"
#import <Foundation/NSData.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSNumber.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <assert.h>

@interface NSPropertyListReader_binary1 (Private)

- (id)_readInlineObjectAtOffset: (unsigned *)offset;

@end


@implementation NSPropertyListReader_binary1

+propertyListFromData:(NSData *)data {
  id                            result=nil;
  NSPropertyListReader_binary1 *reader=[[self alloc] initWithData:data];
  
  if(reader==nil)
   return nil;
  
  result=[reader read];
  [reader release];
  
  return result;
}

#define MAGIC "bplist"
#define FORMAT "00"
#define TRAILER_SIZE (sizeof( uint8_t ) * 2 + sizeof( uint64_t ) * 3)

- (id)initWithData: (NSData *)data
{
        if( (self = [self init]) )
        {
                unsigned magiclen = strlen( MAGIC FORMAT );
                
                BOOL good = YES;
                if( good && [data length] < magiclen + TRAILER_SIZE )
                        good = NO;
                if( good && strncmp( [data bytes], MAGIC FORMAT, magiclen ) != 0 )
                        good = NO;
                
                if( !good )
                {
                        [self release];
                        return nil;
                }
                
                // [data subdataWithRange: NSMakeRange( magiclen, [data length] - magiclen )]
                _data = [data copy];
        }
        return self;
}

- (void)dealloc
{
        [_data release];
        
        [super dealloc];
}

- (uint64_t)_readIntOfSize: (unsigned)size atOffset: (unsigned *)offsetPtr
{
        uint64_t ret = 0;
        const uint8_t *ptr = [_data bytes] + *offsetPtr;
        unsigned i;
        for( i = 0; i < size; i++ )
        {
                ret <<= 8;
                ret |= *ptr;
                ptr++;
        }
        
        *offsetPtr += size;
        
        return ret;
}

- (double)_readFloatOfSize: (unsigned)size atOffset: (unsigned *)offsetPtr
{
        uint64_t val = [self _readIntOfSize: size atOffset: offsetPtr];
        
        if( size == 4 )
        {
                uint32_t val32 = val;
                return *(float *)&val32;
        }
        if( size == 8 )
        {
                return *(double *)&val;
        }
        
        [NSException raise: @"Invalid size" format: @"Don't know how to read float of size %u", size];
        return 0.0;
}

- (void)_readHeader
{
        unsigned trailerStart = [_data length] - TRAILER_SIZE;
        
        _trailerOffsetIntSize           = [self _readIntOfSize: sizeof( _trailerOffsetIntSize )
                                                                                   atOffset: &trailerStart];
        _trailerOffsetRefSize           = [self _readIntOfSize: sizeof( _trailerOffsetRefSize )
                                                                                   atOffset: &trailerStart];
        _trailerNumObjects                   = [self _readIntOfSize: sizeof( _trailerNumObjects )
                                                                                 atOffset: &trailerStart];
        _trailerTopObject                   = [self _readIntOfSize: sizeof( _trailerTopObject )
                                                                                atOffset: &trailerStart];
        _trailerOffsetTableOffset = [self _readIntOfSize: sizeof( _trailerOffsetTableOffset )
                                                                                        atOffset: &trailerStart];
}

static uint64_t ReadSizedInt(NSPropertyListReader_binary1 *bplist, uint64_t offset, uint8_t size)
{
        const uint8_t   *ptr = [bplist->_data bytes];
        unsigned        length=[bplist->_data length];
        
        assert(ptr != NULL && size >= 1 && size <= 8 && offset + size <= length);
        
        uint64_t                result = 0;
        const uint8_t        *byte = ptr + offset;
        
        do
        {
                result = (result << 8) | *byte++;
        } while (--size);
        
        return result;
}

static BOOL ReadSelfSizedInt(NSPropertyListReader_binary1 *bplist, uint64_t offset, uint64_t *outValue, size_t *outSize)
{
        const uint8_t   *ptr = [bplist->_data bytes];
        unsigned        length=[bplist->_data length];
        
        uint32_t                        size;
        int64_t                                value;
        
        assert(ptr != NULL && offset < length);
        
        size = 1 << (ptr[offset] & 0x0F);
        if (size > 8)
        {
                // Maximum allowable size in this implementation is 1<<3 = 8 bytes.
                // This also happens to be the biggest NSNumber can handle.
                return NO;
        }
        
        if (offset + 1+size > length)
        {
                // Out of range.
                return NO;
        }
        
        value = ReadSizedInt(bplist, offset +1, size);
        
        if (outValue != NULL)  *outValue = value;
        if (outSize != NULL)  *outSize = size + 1; // +1 for tag byte.
        return YES;
}

static id ExtractUID(NSPropertyListReader_binary1 *bplist, uint64_t offset)
{
        /*        UIDs are used by Cocoa's key-value coder.
                When writing other plist formats, they are expanded to dictionaries of
                the form <dict><key>CF$UID</key><integer>value</integer></dict>, so we
                do the same here on reading. This results in plists identical to what
                running plutil -convert xml1 gives us. However, this is not the same
                result as [Core]Foundation's plist parser, which extracts them as un-
                introspectable CF objects. In fact, it even seems to convert the CF$UID
                dictionaries from XML plists on the fly.
        */
        
        uint64_t                        value;
        
        if (!ReadSelfSizedInt(bplist, offset, &value, NULL))
        {
                NSLog(@"Bad binary plist: invalid UID object.");
                return nil;
        }
        
        return [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLongLong:value] forKey:@"CF$UID"];
}

- (id)_readObjectAtOffset: (unsigned *)offset
{
        const uint8_t *ptr = [_data bytes];
        uint8_t marker = ptr[*offset];
        
        (*offset)++;
        
        if( marker == 0x00 )
                return [NSNull null];
        if( marker == 0x08 )
                return [NSNumber numberWithBool: NO];
        if( marker == 0x09 )
                return [NSNumber numberWithBool: YES];
        
        uint8_t topNibble = marker >> 4;
        uint8_t botNibble = marker & 0x0F;
        
        if( topNibble == 0x1 )
                return [NSNumber numberWithLongLong: [self _readIntOfSize: 1 << botNibble
                                                                                                                 atOffset: offset]];
        if( topNibble == 0x2 )
                return [NSNumber numberWithDouble: [self _readFloatOfSize: 1 << botNibble
                                                                                                                 atOffset: offset]];
        if( topNibble == 0x3 )
                return [NSDate dateWithTimeIntervalSinceReferenceDate:
                                [self _readFloatOfSize: 8 atOffset: offset]];
        if( topNibble == 0x4 || topNibble == 0x5 || topNibble == 0x6 || topNibble == 0x8 || topNibble == 0xA || topNibble == 0xD )
        {
                uint64_t length = 0;
                if( botNibble != 0xF )
                        length = botNibble;
                else
                        length = [[self _readObjectAtOffset: offset] unsignedLongLongValue];
                
                if( topNibble == 0x4 )
                        return [_data subdataWithRange: NSMakeRange( *offset, length )];
                if( topNibble == 0x5 )
                        return [[[NSString alloc]
                                         initWithData: [_data subdataWithRange: NSMakeRange( *offset, length )]
                                         encoding: NSASCIIStringEncoding] autorelease];
                if( topNibble == 0x6 ){
                
                        return [[[NSString alloc]
                                         initWithData: [_data subdataWithRange: NSMakeRange( *offset, length * 2 )]
                                         encoding: NSUTF16BigEndianStringEncoding] autorelease];
                                     }
                if( topNibble == 0x8 )
                 return ExtractUID(self, (*offset)-1);
                                 
                if( topNibble == 0xA )
                {
                        id result;
                        id *objs = malloc( length * sizeof( *objs ) );
                        uint64_t i;
                        for( i = 0; i < length; i++ )
                                objs[i] = [self _readInlineObjectAtOffset: offset];
                        
                        result=[NSArray arrayWithObjects: objs count: length];
                        free(objs);
                        return result;
                }
                
                if( topNibble == 0xD )
                {
                        id result;
                        id *keys = malloc( length * sizeof( *keys ) );
                        id *objs = malloc( length * sizeof( *objs ) );
                        uint64_t i;
                        for( i = 0; i < length; i++ )
                                keys[i] = [self _readInlineObjectAtOffset: offset];
                        for( i = 0; i < length; i++ )
                                objs[i] = [self _readInlineObjectAtOffset: offset];
                        
                        result=[NSDictionary dictionaryWithObjects: objs
                                                                                           forKeys: keys
                                                                                                 count: length];
                        free(keys);
                        free(objs);
                        return result;
                }
        }
        
        [NSException raise: @"Unknown marker in plist" format: @"Unable to read marker 0x%uX", marker];
        return nil;
}

- (id)_readInlineObjectAtOffset: (unsigned *)offset
{
        // first read the offset table index out of the file
        unsigned objOffset = [self _readIntOfSize: _trailerOffsetRefSize
                                                                         atOffset: offset];
        
        // then transform the index into an offset in the file which points to
        // that offset table entry
        objOffset = _trailerOffsetTableOffset + objOffset * _trailerOffsetIntSize;
        
        // lastly read the offset stored at that entry
        objOffset = [self _readIntOfSize: _trailerOffsetIntSize atOffset: &objOffset];
        
        // and read the object stored there
        return [self _readObjectAtOffset: &objOffset];
        
}

- (id)read
{
        id result=nil;
        
        //@try 
        NS_DURING
        {
                [self _readHeader];

                unsigned offset = _trailerTopObject + strlen( MAGIC FORMAT );
                 result= [self _readObjectAtOffset: &offset];
        }
        NS_HANDLER
        // @catch( id exception )
        {
                NSLog( @"Unable to read binary plist: %@", localException );
        }
        NS_ENDHANDLER
        
        return result;
}

@end
