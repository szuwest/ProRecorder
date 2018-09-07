

#import "RCTWaveChartViewManager.h"
#import "RCTWaveChartView.h"

#import <React/RCTViewManager.h>
#import <UIKit/UIKit.h>

@implementation RCTWaveChartViewManager{

}

RCT_EXPORT_MODULE()

- (UIView *)view
{
  return [[RCTWaveChartView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(lineColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(bgColor, NSString)
RCT_EXPORT_VIEW_PROPERTY(pcmPath, NSString)
RCT_EXPORT_VIEW_PROPERTY(pointOfMs, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(drawUI, BOOL)
RCT_EXPORT_VIEW_PROPERTY(onMessage, RCTDirectEventBlock)

RCT_EXPORT_METHOD(play:(nonnull NSNumber *)reactTag
                  play:(BOOL)play
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
                  ){
  NSLog(@"play: tag %ld, play=%d", (long)reactTag.integerValue, play);
  [self.bridge.uiManager addUIBlock:
   ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTWaveChartView *> *viewRegistry) {
     
     RCTWaveChartView *view = viewRegistry[reactTag];
     if (!view || ![view isKindOfClass:[RCTWaveChartView class]]) {
       RCTLogError(@"Cannot find RCTWaveChartView with tag #%@", reactTag);
       reject(@"-1", @"Cannot find RCTWaveChartView", nil);
       return;
     }
     
     resolve([view play: play]);
   }];
}

RCT_EXPORT_METHOD(record:(nonnull NSNumber *)reactTag
                  record:(BOOL)record
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
                  ){
  NSLog(@"record: tag %ld, record=%d", (long)reactTag.integerValue, record);
  [self.bridge.uiManager addUIBlock:
   ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTWaveChartView *> *viewRegistry) {
     
     RCTWaveChartView *view = viewRegistry[reactTag];
     if (!view || ![view isKindOfClass:[RCTWaveChartView class]]) {
       RCTLogError(@"Cannot find RCTWaveChartView with tag #%@", reactTag);
       reject(@"-1", @"Cannot find RCTWaveChartView", nil);
       return;
     }
     
     resolve([view record: record]);
   }];
}

@end
