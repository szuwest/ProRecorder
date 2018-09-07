//
//  UIColor+XL.m
//  XL
//
//  Created by west on 2018/1/11.
//  Copyright © 2018年 SpeakIn. All rights reserved.
//

#import "UIColor+XL.h"

@implementation UIColor (XL)

+ (UIColor *)color255WithRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue{
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:255.0/255.0];
}

+ (UIColor *)color255WithRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha {
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha/255.0];
}

+ (UIColor *)colorWithHexString:(NSString *)stringToConvert
{
    return [UIColor colorWithHexString:stringToConvert alpha:1.0];
}

+ (UIColor *)colorWithHexString:(NSString *)stringToConvert alpha:(CGFloat)alpha
{
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) return [UIColor whiteColor];
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"] || [cString hasPrefix:@"0x"]) cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    if ([cString length] != 6) return [UIColor whiteColor];
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:alpha];
}

+ (UIColor *)randomColor
{
    srand([[NSDate date] timeIntervalSince1970]);
    return [UIColor color255WithRed:abs(rand()%256) green:abs(rand()%256) blue:abs(rand()%256)];
}

- (CGFloat)red {
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
    const CGFloat* components = CGColorGetComponents(self.CGColor);
    switch (colorSpaceModel) {
        case kCGColorSpaceModelMonochrome:
            return components[0];
            
        case kCGColorSpaceModelRGB:
            return components[0];
            
        default:
            NSLog(@"XL: Unsupported UIColor space!");
            break;
    }
    return 0.0;
}

- (CGFloat)green {
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
    const CGFloat* components = CGColorGetComponents(self.CGColor);
    switch (colorSpaceModel) {
        case kCGColorSpaceModelMonochrome:
            return components[0];
            
        case kCGColorSpaceModelRGB:
            return components[1];
            
        default:
            NSLog(@"XL: Unsupported UIColor space!");
            break;
    }
    return 0.0;
}

- (CGFloat)blue {
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
    const CGFloat* components = CGColorGetComponents(self.CGColor);
    switch (colorSpaceModel) {
        case kCGColorSpaceModelMonochrome:
            return components[0];
            
        case kCGColorSpaceModelRGB:
            return components[2];
            
        default:
            NSLog(@"XL: Unsupported UIColor space!");
            break;
    }
    return 0.0;
}

- (CGFloat) alpha{
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
    const CGFloat* components = CGColorGetComponents(self.CGColor);
    switch (colorSpaceModel) {
        case kCGColorSpaceModelMonochrome:
            return components[1];
            
        case kCGColorSpaceModelRGB:
            return components[3];
            
        default:
            NSLog(@"XL: Unsupported UIColor space!");
            break;
    }
    return 0.0;
}

@end
