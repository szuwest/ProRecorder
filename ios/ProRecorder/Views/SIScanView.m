//
//  SIScanView.m
//
//  Created by west on 2018/1/11.
//  Copyright © 2018年 SpeakIn. All rights reserved.
//

#import "SIScanView.h"
#import "UIColor+XL.h"

@interface SIScanView () {
	
}
@property (nonatomic, strong) CAShapeLayer *bgLayer;
@property (nonatomic, strong) CAShapeLayer *scanMaskLayer;
@property (nonatomic, strong) UIView *scanView;

@end

@implementation SIScanView

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self _init];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self _init];
	}
	return self;
}

- (void)_init {
  if (self.bgLayer) {
    [self.bgLayer removeFromSuperlayer];
  }
  if (self.scanView) {
    [self.scanView removeFromSuperview];
  }
	self.rectWith = 200;
	int radius = self.rectWith/2.0;
	CGRect myRect = CGRectMake(self.frame.size.width/2-radius,self.frame.size.height/2-radius,2.0*radius,2.0*radius);
	
	UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0, self.bounds.size.width, self.bounds.size.height) cornerRadius:0];
	
	UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:myRect cornerRadius:radius];
	
	[path appendPath:circlePath];
	
	[path setUsesEvenOddFillRule:YES];
	
	CAShapeLayer *fillLayer = [CAShapeLayer layer];
	
	fillLayer.path = path.CGPath;
	
	fillLayer.fillRule = kCAFillRuleEvenOdd;
	
	fillLayer.fillColor = [UIColor colorWithRed:0x0f/255.0 green:0x16/255.0 blue:0x1f/255.0 alpha:1].CGColor;
	
//	fillLayer.opacity = 0.5;
  self.bgLayer = fillLayer;
	[self.layer addSublayer:fillLayer];
	
	CAShapeLayer *maskLayer = [CAShapeLayer layer];
	maskLayer.frame = myRect;
	maskLayer.fillColor = [UIColor greenColor].CGColor; // Any color but clear will be OK
	maskLayer.path =  [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0, self.rectWith, self.rectWith) cornerRadius:0].CGPath;
	maskLayer.position = CGPointMake(radius, -radius);
	self.scanMaskLayer = maskLayer;
	
	self.scanView = [[UIView alloc] initWithFrame:myRect];
	self.scanView.backgroundColor = [UIColor colorWithRed:0xac/255.0 green:0xe2/255.0 blue:0xfc/255.0 alpha:0.5];
	self.scanView.layer.cornerRadius = radius;
	self.scanView.clipsToBounds = YES;
	[self addSubview:self.scanView];
	
	self.scanView.layer.mask = maskLayer;
}

- (void)startScanAnim {
  CABasicAnimation *downAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
  CGFloat radius = self.rectWith/2.0;
  downAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(radius, -radius)];
  downAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(radius, 2*radius)];
  downAnimation.duration = 0.32;
  //  downAnimation.repeatCount = 100000;
  
  CABasicAnimation *opacityAnim = [CABasicAnimation animationWithKeyPath:@"alpha"];
  opacityAnim.fromValue = [NSNumber numberWithFloat:0.5];
  opacityAnim.toValue = [NSNumber numberWithFloat:0.0];
  opacityAnim.removedOnCompletion = YES;
  opacityAnim.duration = 0.16;
  opacityAnim.beginTime = 0.16;
  
  CABasicAnimation *upAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
  upAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(radius, 2*radius)];
  upAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(radius, -radius)];
  upAnimation.duration = 0.26;
  upAnimation.beginTime = 0.32;
  //  upAnimation.repeatCount = 100000;
  
  CABasicAnimation *opacityAnim2 = [CABasicAnimation animationWithKeyPath:@"alpha"];
  opacityAnim2.fromValue = [NSNumber numberWithFloat:0.5];
  opacityAnim2.toValue = [NSNumber numberWithFloat:0.0];
  opacityAnim2.removedOnCompletion = YES;
  opacityAnim2.duration = 0.13;
  opacityAnim2.beginTime = 0.32+0.13;
  
  CAAnimationGroup *animGroup = [CAAnimationGroup animation];
  animGroup.animations = [NSArray arrayWithObjects:downAnimation, opacityAnim, upAnimation, opacityAnim2, nil];
  animGroup.duration = 0.58;
  animGroup.repeatCount = 10000;
  
  [self.scanMaskLayer addAnimation:animGroup forKey:@"scan"];
}

- (void)stopScanAnim {
	[self.scanMaskLayer removeAllAnimations];
}

-(void)setFrame:(CGRect)newFrame {
//  BOOL const isResize = !CGSizeEqualToSize(newFrame.size, self.frame.size);
//  if (isResize) [self _init]; // probably saves
  [super setFrame:newFrame];
//  if (isResize) [self recoverFromResizing];
  NSLog(@"frame=%@", NSStringFromCGRect(newFrame));
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self _init];
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self startScanAnim];
  });
  
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)setBgColor:(NSString *)bgColor {
  _bgColor = [bgColor copy];
  self.bgLayer.fillColor = [UIColor colorWithHexString:bgColor].CGColor;
}

- (void)setScanColor:(NSString *)scanColor {
  _scanColor = [scanColor copy];
  self.scanView.backgroundColor = [UIColor colorWithHexString:scanColor alpha:0.5];
}

@end
