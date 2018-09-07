//
//  NSData+XL.m
//  XL
//
//

#import "NSData+XL.h"

@implementation NSData (XL)

#define BASE64_GETC (length > 0 ? (length--, bytes++, (unsigned int)(bytes[-1])) : (unsigned int)EOF)
#define BASE64_PUTC(c) [buffer appendBytes: &c length: 1]
static char basis_64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static inline void output64Chunk( int c1, int c2, int c3, int pads, NSMutableData * buffer )
{
    char pad = '=';
    BASE64_PUTC(basis_64[c1 >> 2]);
    BASE64_PUTC(basis_64[((c1 & 0x3) << 4) | ((c2 & 0xF0) >> 4)]);
    
    switch ( pads )
    {
        case 2:
            BASE64_PUTC(pad);
            BASE64_PUTC(pad);
            break;
            
        case 1:
            BASE64_PUTC(basis_64[((c2 & 0xF) << 2) | ((c3 & 0xC0) >> 6)]);
            BASE64_PUTC(pad);
            break;
            
        default:
        case 0:
            BASE64_PUTC(basis_64[((c2 & 0xF) << 2) | ((c3 & 0xC0) >> 6)]);
            BASE64_PUTC(basis_64[c3 & 0x3F]);
            break;
    }
}

- (NSString *) base64EncodedString
{
    NSMutableData * buffer = [NSMutableData data];
    const unsigned char * bytes;
    NSUInteger length;
    unsigned int c1, c2, c3;
    
    bytes = [self bytes];
    length = [self length];
    
    while ( (c1 = BASE64_GETC) != (unsigned int)EOF )
    {
        c2 = BASE64_GETC;
        if ( c2 == (unsigned int)EOF )
        {
            output64Chunk( c1, 0, 0, 2, buffer );
        }
        else
        {
            c3 = BASE64_GETC;
            if ( c3 == (unsigned int)EOF )
                output64Chunk( c1, c2, 0, 1, buffer );
            else
                output64Chunk( c1, c2, c3, 0, buffer );
        }
    }
    
    return ( [[NSString allocWithZone: nil] initWithData: buffer encoding: NSASCIIStringEncoding] );
}

+ (NSData *)dataWithBase64EncodedString:(NSString *)str
{
    const char lookup[] =
    {
        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99,
        99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 99, 62, 99, 99, 99, 63,
        52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 99, 99, 99, 99, 99, 99,
        99, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 99, 99, 99, 99, 99,
        99, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
        41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 99, 99, 99, 99, 99
    };
    
    NSData *inputData = [str dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    long long inputLength = [inputData length];
    const unsigned char *inputBytes = [inputData bytes];
    
    long long maxOutputLength = (inputLength / 4 + 1) * 3;
    NSMutableData *outputData = [NSMutableData dataWithLength:(NSUInteger)maxOutputLength];
    unsigned char *outputBytes = (unsigned char *)[outputData mutableBytes];
    
    int accumulator = 0;
    NSUInteger outputLength = 0;
    unsigned char accumulated[] = {0, 0, 0, 0};
    for (long long i = 0; i < inputLength; i++)
    {
        unsigned char decoded = lookup[inputBytes[i] & 0x7F];
        if (decoded != 99)
        {
            accumulated[accumulator] = decoded;
            if (accumulator == 3)
            {
                outputBytes[outputLength++] = (accumulated[0] << 2) | (accumulated[1] >> 4);
                outputBytes[outputLength++] = (accumulated[1] << 4) | (accumulated[2] >> 2);
                outputBytes[outputLength++] = (accumulated[2] << 6) | accumulated[3];
            }
            accumulator = (accumulator + 1) % 4;
        }
    }
    
    //handle left-over data
    if (accumulator > 0) outputBytes[outputLength] = (accumulated[0] << 2) | (accumulated[1] >> 4);
    if (accumulator > 1) outputBytes[++outputLength] = (accumulated[1] << 4) | (accumulated[2] >> 2);
    if (accumulator > 2) outputLength++;
    
    //truncate data to match actual output length
    outputData.length = outputLength;
    
    return outputLength? outputData: nil;
}

- (NSData *)dataByHealingUTF8Stream
{//将非utf8编码部分用�替代
    NSUInteger length = [self length];
    
    if (length == 0) return self;
    
#if DEBUG
    int warningsCounter = 10;
#endif
    
    //  bits
    //  7   	U+007F      0xxxxxxx
    //  11   	U+07FF      110xxxxx	10xxxxxx
    //  16  	U+FFFF      1110xxxx	10xxxxxx	10xxxxxx
    //  21  	U+1FFFFF    11110xxx	10xxxxxx	10xxxxxx	10xxxxxx
    //  26  	U+3FFFFFF   111110xx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx
    //  31  	U+7FFFFFFF  1111110x	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx	10xxxxxx
    
#define b00000000 0x00
#define b10000000 0x80
#define b11000000 0xc0
#define b11100000 0xe0
#define b11110000 0xf0
#define b11111000 0xf8
#define b11111100 0xfc
#define b11111110 0xfe
    
    static NSString* replacementCharacter = @"�";//用于替换非utf8编码的乱码
    NSData* replacementCharacterData = [replacementCharacter dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData* resultData = [NSMutableData dataWithCapacity:[self length]];
    
    const char *bytes = [self bytes];
    
    
    static const NSUInteger bufferMaxSize = 1024;
    char buffer[bufferMaxSize]; // not initialized, but will be filled in completely before copying to resultData
    NSUInteger bufferIndex = 0;
    
#define FlushBuffer() if (bufferIndex > 0) { \
[resultData appendBytes:buffer length:bufferIndex]; \
bufferIndex = 0; \
}
#define CheckBuffer() if ((bufferIndex+5) >= bufferMaxSize) { \
[resultData appendBytes:buffer length:bufferIndex]; \
bufferIndex = 0; \
}
    
    NSUInteger byteIndex = 0;
    BOOL invalidByte = NO;
    while (byteIndex < length)
    {
        char byte = bytes[byteIndex];
        
        // ASCII character is always a UTF-8 character
        if ((byte & b10000000) == b00000000) // 0xxxxxxx
        {
            CheckBuffer();
            buffer[bufferIndex++] = byte;
        }
        else if ((byte & b11100000) == b11000000) // 110xxxxx 10xxxxxx
        {
            if (byteIndex+1 >= length) {
                FlushBuffer();
                return resultData;
            }
            char byte2 = bytes[++byteIndex];
            if ((byte2 & b11000000) == b10000000)
            {
                // This 2-byte character still can be invalid. Check if we can create a string with it.
                unsigned char tuple[] = {byte, byte2};
                CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 2, kCFStringEncodingUTF8, false);
                if (cfstr)
                {
                    CFRelease(cfstr);
                    CheckBuffer();
                    buffer[bufferIndex++] = byte;
                    buffer[bufferIndex++] = byte2;
                }
                else
                {
                    invalidByte = YES;
                }
            }
            else
            {
                byteIndex -= 1;
                invalidByte = YES;
            }
        }
        else if ((byte & b11110000) == b11100000) // 1110xxxx 10xxxxxx 10xxxxxx
        {
            if (byteIndex+2 >= length) {
                FlushBuffer();
                return resultData;
            }
            char byte2 = bytes[++byteIndex];
            char byte3 = bytes[++byteIndex];
            if ((byte2 & b11000000) == b10000000 &&
                (byte3 & b11000000) == b10000000)
            {
                // This 3-byte character still can be invalid. Check if we can create a string with it.
                unsigned char tuple[] = {byte, byte2, byte3};
                CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 3, kCFStringEncodingUTF8, false);
                if (cfstr)
                {
                    CFRelease(cfstr);
                    CheckBuffer();
                    buffer[bufferIndex++] = byte;
                    buffer[bufferIndex++] = byte2;
                    buffer[bufferIndex++] = byte3;
                }
                else
                {
                    invalidByte = YES;
                }
            }
            else
            {
                byteIndex -= 2;
                invalidByte = YES;
            }
        }
        else if ((byte & b11111000) == b11110000) // 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        {
            if (byteIndex+3 >= length) {
                FlushBuffer();
                return resultData;
            }
            char byte2 = bytes[++byteIndex];
            char byte3 = bytes[++byteIndex];
            char byte4 = bytes[++byteIndex];
            if ((byte2 & b11000000) == b10000000 &&
                (byte3 & b11000000) == b10000000 &&
                (byte4 & b11000000) == b10000000)
            {
                // This 4-byte character still can be invalid. Check if we can create a string with it.
                unsigned char tuple[] = {byte, byte2, byte3, byte4};
                CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 4, kCFStringEncodingUTF8, false);
                if (cfstr)
                {
                    CFRelease(cfstr);
                    CheckBuffer();
                    buffer[bufferIndex++] = byte;
                    buffer[bufferIndex++] = byte2;
                    buffer[bufferIndex++] = byte3;
                    buffer[bufferIndex++] = byte4;
                }
                else
                {
                    invalidByte = YES;
                }
            }
            else
            {
                byteIndex -= 3;
                invalidByte = YES;
            }
        }
        else if ((byte & b11111100) == b11111000) // 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
        {
            if (byteIndex+4 >= length) {
                FlushBuffer();
                return resultData;
            }
            char byte2 = bytes[++byteIndex];
            char byte3 = bytes[++byteIndex];
            char byte4 = bytes[++byteIndex];
            char byte5 = bytes[++byteIndex];
            if ((byte2 & b11000000) == b10000000 &&
                (byte3 & b11000000) == b10000000 &&
                (byte4 & b11000000) == b10000000 &&
                (byte5 & b11000000) == b10000000)
            {
                // This 5-byte character still can be invalid. Check if we can create a string with it.
                unsigned char tuple[] = {byte, byte2, byte3, byte4, byte5};
                CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 5, kCFStringEncodingUTF8, false);
                if (cfstr)
                {
                    CFRelease(cfstr);
                    CheckBuffer();
                    buffer[bufferIndex++] = byte;
                    buffer[bufferIndex++] = byte2;
                    buffer[bufferIndex++] = byte3;
                    buffer[bufferIndex++] = byte4;
                    buffer[bufferIndex++] = byte5;
                }
                else
                {
                    invalidByte = YES;
                }
            }
            else
            {
                byteIndex -= 4;
                invalidByte = YES;
            }
        }
        else if ((byte & b11111110) == b11111100) // 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
        {
            if (byteIndex+5 >= length) {
                FlushBuffer();
                return resultData;
            }
            char byte2 = bytes[++byteIndex];
            char byte3 = bytes[++byteIndex];
            char byte4 = bytes[++byteIndex];
            char byte5 = bytes[++byteIndex];
            char byte6 = bytes[++byteIndex];
            if ((byte2 & b11000000) == b10000000 &&
                (byte3 & b11000000) == b10000000 &&
                (byte4 & b11000000) == b10000000 &&
                (byte5 & b11000000) == b10000000 &&
                (byte6 & b11000000) == b10000000)
            {
                // This 6-byte character still can be invalid. Check if we can create a string with it.
                unsigned char tuple[] = {byte, byte2, byte3, byte4, byte5, byte6};
                CFStringRef cfstr = CFStringCreateWithBytes(kCFAllocatorDefault, tuple, 6, kCFStringEncodingUTF8, false);
                if (cfstr)
                {
                    CFRelease(cfstr);
                    CheckBuffer();
                    buffer[bufferIndex++] = byte;
                    buffer[bufferIndex++] = byte2;
                    buffer[bufferIndex++] = byte3;
                    buffer[bufferIndex++] = byte4;
                    buffer[bufferIndex++] = byte5;
                    buffer[bufferIndex++] = byte6;
                }
                else
                {
                    invalidByte = YES;
                }
                
            }
            else
            {
                byteIndex -= 5;
                invalidByte = YES;
            }
        }
        else
        {
            invalidByte = YES;
        }
        
        if (invalidByte)
        {
#if DEBUG
            if (warningsCounter)
            {
                warningsCounter--;
                //NSLog(@"NSData dataByHealingUTF8Stream: broken byte encountered at index %d", byteIndex);
            }
#endif
            invalidByte = NO;
            FlushBuffer();
            [resultData appendData:replacementCharacterData];
        }
        
        byteIndex++;
    }
    FlushBuffer();
    return resultData;
}

+ (NSData *)dataWithRect:(CGRect)rect
{
    return [NSData dataWithBytes:&rect length:sizeof(rect)];
}

- (CGRect)rectValue
{
    CGRect rect = {0};
    [self getBytes:&rect length:sizeof(rect)];
    return rect;
}

- (NSString *)utf8String:(BOOL)force
{
    NSString* str = [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
    if (str || !force)
    {
        return str;
    }
    str  = [[NSString alloc] initWithData:[self dataByHealingUTF8Stream] encoding:NSUTF8StringEncoding];
    return str;
}

- (NSString *)hexString
{
    NSMutableString *stringBuffer = [NSMutableString stringWithCapacity:([self length] * 2)];
    
    const unsigned char *dataBuffer = [self bytes];
    int i;
    
    for (i = 0; i < [self length]; ++i) {
        [stringBuffer appendFormat:@"%02x", (unsigned char)dataBuffer[i]];
    }
    
    return stringBuffer;
}

+ (NSData *)dataWithHexString:(NSString *)str
{
    if (str.length == 0 || str.length % 2 != 0) {
        NSLog(@"Hex string to NSData error: invalid hex string!");
        return nil;
    }
    
    NSMutableData *result = [NSMutableData data];
    unsigned char whole_byte;
    char byte_chars[3] = {0};
    int i;
    for (i = 0; i < [str length] / 2; ++i) {
        byte_chars[0] = [str characterAtIndex:i * 2];
        byte_chars[1] = [str characterAtIndex:i * 2 + 1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [result appendBytes:&whole_byte length:1];
    }
    return result;
}

+ (NSData *)randomDataOfLength:(NSUInteger)length
{
    NSMutableData *data = [NSMutableData dataWithLength:length];
    
    __unused int result = SecRandomCopyBytes(kSecRandomDefault, length, data.mutableBytes);
    NSAssert(result == 0, @"Unable to generate random bytes: %d", errno);
    
    return data;
}

- (id)jsonFormat
{
    NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:self options:NSJSONReadingAllowFragments error:&error];
    if (error)
    {
        NSLog(@"%s error:%@ data:%@",__FUNCTION__,error,[[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding]);
    }
    return result;
}

@end
