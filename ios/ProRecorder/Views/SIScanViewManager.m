//
//  SIScanViewManager.m
//  VprScene
//
//  Created by west on 2018/1/11.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "SIScanViewManager.h"
#import "SIScanView.h"

@implementation SIScanViewManager

RCT_EXPORT_MODULE()

- (UIView *)view
{
  return [SIScanView new];
}

RCT_EXPORT_VIEW_PROPERTY(scanColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(bgColor, NSString)

@end
