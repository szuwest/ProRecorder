//
//  UIColor+XL.h
//  XL
//
//  Created by west on 2018/1/11.
//  Copyright © 2018年 SpeakIn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (XL)

@property (nonatomic, readonly) CGFloat red;
@property (nonatomic, readonly) CGFloat green;
@property (nonatomic, readonly) CGFloat blue;
@property (nonatomic, readonly) CGFloat alpha;

+ (UIColor *)color255WithRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue;
+ (UIColor *)color255WithRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue alpha:(NSInteger)alpha;

+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert alpha:(CGFloat)alpha;

+ (UIColor *)randomColor;

@end
