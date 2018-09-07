
#import "RCTWaveChartView.h"
#import "AudioRecorderReact.h"
#import "SIAudioInputQueue.h"
#import "AudioQueuePlay.h"
#import "AppDelegate.h"

typedef enum { R, G, B, A } UIColorComponentIndices;

@interface RCTWaveChartView() <SIAudioInputQueueDelegate,AudioQueuePlayQueueDelegate> {
  RCTPromiseResolveBlock _errorJsCallback;
}
  @property (assign, nonatomic) NSString* lineColor;
  @property (assign, nonatomic) NSString* bgColor;
  @property (assign, nonatomic) NSString* pcmPath;
  @property (assign, nonatomic) int pointOfMs;
  @property (assign, nonatomic) BOOL drawUI;
  @property (nonatomic, strong) SIAudioInputQueue *record;
  @property (nonatomic, strong) AudioQueuePlay *play;
  @property (nonatomic, copy) NSString *currentVoicePath;
  @property (nonatomic, strong)NSMutableArray *recordData;
  @property (nonatomic, strong)NSMutableArray *uiPathData;
  @property (assign, nonatomic)int maxPoint,_width,_height,_halfHeight;
  @property (nonatomic, strong) UIColor *LINEColor;
@property (nonatomic, strong) UIColor *BGColor;
@end

@implementation RCTWaveChartView

- (void)initVar{
  
//  self.record = [SIAudioInputQueue defaultInputQueue];
//  self.record.delegate = self;
  self.record = ((AppDelegate *)[UIApplication sharedApplication].delegate).audioRecorder;
  [self.record addObserver:self];
//  self.play = [[AudioQueuePlay alloc] init];
//  self.play.delegate = self;
  self.play = ((AppDelegate *)[UIApplication sharedApplication].delegate).audioPlayer;
  [self.play addObserver:self];
  self.recordData = [ [NSMutableArray alloc] init];
  self.uiPathData = [ [NSMutableArray alloc] init];
  self.drawUI = true;
  [self setDrawUI:self.drawUI];
  self.pointOfMs = 400;
  [self setMaxPoint:self.pointOfMs];
  self.lineColor = @"#4499dd";
  [self setLineColor:self.lineColor];
  self.bgColor = @"#000000";
  [self setBgColor:self.bgColor];
}
- (instancetype)init {
  NSLog(@"init");
  self = [super init];
  if ( self ) {
    [self initVar];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  NSLog(@"initWithFrame");
  self = [super initWithFrame:frame];
  if (self) {
    NSLog(@"init");
    [self initVar];
  }
  return self;
}

- (void)dealloc{
  if(self.record.isRunning){
    [self.record stop];
    //    self.record.delegate = nil;
  }
  [self.record removeObserver:self];
  if (self.play.isPlaying) {
    [self.play stop];
//    self.play.delegate = nil;
  }
  [self.play removeObserver:self];
}

- (NSString*) play:(BOOL) play{
  [self.uiPathData removeAllObjects];
  [self.recordData removeAllObjects];
  if( self.play.isPlaying != play ){
    if(play){
      [self.play play];
      return @"play start";
    } else {
      [self.play stop];
      return @"play stop";
    }
  }
  return @"not opt";
}

- (NSString*) record:(BOOL) record{
  [self.uiPathData removeAllObjects];
  [self.recordData removeAllObjects];
  if(self.record.isRunning != record){
    if (record){
      self.currentVoicePath = [self createSavePath];
      self.record.audioSavePath = self.currentVoicePath;
      BOOL succ = [self.record start];
      if(succ){ self.onMessage(@{@"eventName":@"recordStart"}); }
      return succ ? @"start succ" : @"start fail";
    } else {
      [self.record stop];
      self.onMessage(@{ @"eventName":@"recordEnd", @"filePath":self.currentVoicePath});
      return @"stop succ";
    }
  }
  return @"not operating";
}

- (NSArray*) getMinAndMax{
  NSNumber *min = self.recordData[0],*max = self.recordData[0];
  for(int i=0; i< [self.recordData count]; i++){
    if( [self.recordData[i] compare:max ] == NSOrderedAscending ) max = self.recordData[i];
    if( [self.recordData[i] compare:min ] == NSOrderedDescending ) min = self.recordData[i];
  }
  return [NSArray arrayWithObjects: min,max,nil ];
}

- (void)onRecordData:(short*)data dataLen:(int)dataLen {
  if(self.record.isRunning == false && self.play.isPlaying == false) return ;
  if( ! self.drawUI ) return;
  NSMutableArray *tmpData =  [ [NSMutableArray alloc] init];
  @try{
    for(int i=0;i<dataLen;i++){
      if( [self.recordData count] == _maxPoint ){
        [tmpData addObject: [self getMinAndMax]];
        [self.recordData removeAllObjects];
      } else {
          [self.recordData addObject: [ NSNumber numberWithInt:(int)data[i] ] ];
      }
    }
    [self reDraw:tmpData];
  }@catch (NSException *exception) {
    NSLog(@"%@", exception);
  }
}

- (void)reDraw:(NSMutableArray*)data {
  while( [self.uiPathData count] > (self._width - 40) ){
    [ self.uiPathData removeObjectAtIndex:0 ];
  }
  for(NSArray *item in data){
    int min = ( [item[0] intValue] * self._halfHeight / 32768 ) + self._halfHeight;
    int max = ( [item[1] intValue] * self._halfHeight / 32768 ) + self._halfHeight;
    [self.uiPathData addObject:  [NSArray arrayWithObjects: [NSNumber numberWithInt:min] ,[NSNumber numberWithInt:max], nil ] ];
  }
  [self setNeedsDisplay];
}

- (void)inputQueue:(SIAudioInputQueue *)inputQueue inputData:(NSData *)data numberOfPackets:(NSNumber *)numberOfPackets {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self onRecordData:(short *)[data bytes] dataLen:(int)data.length/2];
  });
}

- (void)inputQueue:(SIAudioInputQueue *)inputQueue errorOccur:(NSError *)error {
  [self.record stop];
}

- (void)inputQueue:(SIAudioInputQueue *)inputQueue didStop:(NSString *)audioSavePath {
  NSLog(@"didStop");
  if (!audioSavePath) {}
}

- (void)audioPlay:(AudioQueuePlay *)audioPlay playData:(NSData *)data {
  dispatch_async(dispatch_get_main_queue(), ^{
    [self onRecordData:(short *)[data bytes] dataLen:(int)data.length/2];
  });
}
- (void)audioPlay:(AudioQueuePlay *)audioPlay didPlayStop:(NSNumber *)t {
  self.onMessage(@{ @"eventName":@"playEnd"});
}
- (void)audioPlay:(AudioQueuePlay *)audioPlay didPlayStart:(NSNumber *)t {
  self.onMessage(@{ @"eventName":@"playStart"});
}
- (void)audioPlay:(AudioQueuePlay *)audioPlay playProgress:(NSNumber *)ms totalMs:(NSNumber *)totalMs {
  self.onMessage(@{ @"eventName":@"playProgress",@"ms":[NSString stringWithFormat:@"%d",ms.intValue], @"totalMs":[NSString stringWithFormat:@"%d",totalMs.intValue] });
}

- (NSString *)createSavePath {
  NSString *docsDir = NSTemporaryDirectory();
  NSString *voiceFileName = [NSString stringWithFormat:@"%ld.pcm", (long)[[NSDate date] timeIntervalSince1970] ];
  return [docsDir stringByAppendingPathComponent:voiceFileName];
}

- (void)drawRect:(CGRect)rect
{
  [self.BGColor setFill];
  UIRectFill(rect);
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  
  self._width = CGRectGetWidth(rect);
  self._height = CGRectGetHeight(rect);
  self._halfHeight = self._height/2;
  
  CGContextSetLineWidth(ctx, 1);
  CGContextSetStrokeColorWithColor( ctx , self.LINEColor.CGColor );
  int idx = 0;
  for(NSArray *item in self.uiPathData){
    int min = [item[0] intValue], max = [item[1] intValue];
    if(min != max){
      CGContextMoveToPoint(ctx,idx,min);
      CGContextAddLineToPoint(ctx,idx,max);
    } else {
      CGContextMoveToPoint(ctx,idx-1,self._halfHeight);
      CGContextAddLineToPoint(ctx,idx+1,self._halfHeight);
    }
    idx++;
  }
  CGContextMoveToPoint(ctx,idx, self._halfHeight);
  CGContextAddLineToPoint(ctx,self._width, self._halfHeight);
  CGContextStrokePath(ctx);
}

- (UIColor *) colorWithHexString: (NSString *)color
{
  NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
  
  if ([cString length] < 4) {
    return [UIColor clearColor];
  }
  if ([cString hasPrefix:@"0X"])
    cString = [cString substringFromIndex:2];
  if ([cString hasPrefix:@"#"])
    cString = [cString substringFromIndex:1];
  if ([cString length] == 3){
    cString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
               [cString substringWithRange:NSMakeRange(0, 1)],[cString substringWithRange:NSMakeRange(0, 1)],
               [cString substringWithRange:NSMakeRange(1, 1)],[cString substringWithRange:NSMakeRange(1, 1)],
               [cString substringWithRange:NSMakeRange(2, 1)],[cString substringWithRange:NSMakeRange(2, 1)]
        ];
  }
  if ([cString length] != 6)
    return [UIColor clearColor];
  
  NSRange range= NSMakeRange(0, 2);
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
  
  return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}
- (void)setLineColor:(NSString*) lineColor { self.LINEColor = [self colorWithHexString:lineColor]; }
- (void)setBgColor:(NSString *)bgColor { self.BGColor = [self colorWithHexString:bgColor]; }
- (void)setPcmPath:(NSString*) pcmPath { self.play.pcmFile = pcmPath; }
- (void)setPointOfMs:(int) pointOfMs {
  _pointOfMs = pointOfMs;
  _maxPoint = (16000 / 1000 * pointOfMs);
}
- (void)setDrawUI:(BOOL) drawUI {_drawUI = drawUI;}
@end
