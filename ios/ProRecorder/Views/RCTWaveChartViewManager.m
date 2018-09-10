

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

RCT_EXPORT_METHOD(listenOnPlay:(nonnull NSNumber *)reactTag
                  listen:(BOOL)listen
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
                  ){
  NSLog(@"play: tag %ld, play=%d", (long)reactTag.integerValue, listen);
  [self.bridge.uiManager addUIBlock:
   ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTWaveChartView *> *viewRegistry) {
     
     RCTWaveChartView *view = viewRegistry[reactTag];
     if (!view || ![view isKindOfClass:[RCTWaveChartView class]]) {
       RCTLogError(@"Cannot find RCTWaveChartView with tag #%@", reactTag);
       reject(@"-1", @"Cannot find RCTWaveChartView", nil);
       return;
     }
     
     resolve([view listenOnPlay: listen]);
   }];
}

RCT_EXPORT_METHOD(listenOnRecord:(nonnull NSNumber *)reactTag
                  listen:(BOOL)listen
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
                  ){
  NSLog(@"record: tag %ld, record=%d", (long)reactTag.integerValue, listen);
  [self.bridge.uiManager addUIBlock:
   ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTWaveChartView *> *viewRegistry) {
     
     RCTWaveChartView *view = viewRegistry[reactTag];
     if (!view || ![view isKindOfClass:[RCTWaveChartView class]]) {
       RCTLogError(@"Cannot find RCTWaveChartView with tag #%@", reactTag);
       reject(@"-1", @"Cannot find RCTWaveChartView", nil);
       return;
     }
     
     resolve([view listenOnRecord:listen]);
   }];
}

RCT_EXPORT_METHOD(reset:(nonnull NSNumber *)reactTag
                  reset:(BOOL)reset
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
                  ){
  [self.bridge.uiManager addUIBlock:
   ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTWaveChartView *> *viewRegistry) {
     
     RCTWaveChartView *view = viewRegistry[reactTag];
     if (!view || ![view isKindOfClass:[RCTWaveChartView class]]) {
       RCTLogError(@"Cannot find RCTWaveChartView with tag #%@", reactTag);
       reject(@"-1", @"Cannot find RCTWaveChartView", nil);
       return;
     }
     [view reset:reset];
     resolve(nil);
   }];
}

@end
