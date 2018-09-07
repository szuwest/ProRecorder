//
//  NSData+XL.h
//  XL
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSData (XL)

- (NSString *)base64EncodedString;
+ (NSData *)dataWithBase64EncodedString:(NSString *)str;

+ (NSData *)dataWithRect:(CGRect)rect;
- (CGRect)rectValue;

- (NSString *)utf8String:(BOOL)force;
- (NSString *)hexString;
+ (NSData *)dataWithHexString:(NSString *)str;

+ (NSData *)randomDataOfLength:(NSUInteger)length;

- (id)jsonFormat;

@end
