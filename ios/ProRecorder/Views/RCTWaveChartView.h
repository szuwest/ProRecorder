

#import <React/RCTBridge.h>
#import <React/UIView+React.h>

#import <UIKit/UIKit.h>
#import <React/RCTBridge.h>

@interface RCTWaveChartView : UIView

@property (nonatomic, copy) RCTDirectEventBlock onMessage;

- (NSString*) play:(BOOL) play;
- (NSString*) record:(BOOL) record;

@end
