//
//  SIScanView.h
//
//  Created by west on 2018/1/11.
//  Copyright © 2018年 SpeakIn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SIScanView : UIView
//圆形直径，默认200
@property (nonatomic, assign) NSUInteger rectWith;

@property (nonatomic, copy) NSString *bgColor;
@property (nonatomic, copy) NSString *scanColor;

- (void)startScanAnim;

- (void)stopScanAnim;

@end
