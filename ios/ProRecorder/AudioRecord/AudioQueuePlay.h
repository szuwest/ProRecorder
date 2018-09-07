#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#include "XLObserverHoster.h"

@class AudioQueuePlay;
@protocol AudioQueuePlayQueueDelegate <NSObject>
@required
- (void)audioPlay:(AudioQueuePlay *)audioPlay playData:(NSData *)data;
  - (void)audioPlay:(AudioQueuePlay *)audioPlay didPlayStop:(NSNumber *)t;
  - (void)audioPlay:(AudioQueuePlay *)audioPlay didPlayStart:(NSNumber *)t;
  - (void)audioPlay:(AudioQueuePlay *)audioPlay playProgress:(NSNumber *)ms totalMs:(NSNumber *)totalMs;
@end

@interface AudioQueuePlay : XLObserverHoster

//@property (nonatomic,weak) id<AudioQueuePlayQueueDelegate> delegate;
@property (nonatomic,copy) NSString *pcmFile;
@property (nonatomic,assign,readonly) UInt32 maxPacketSize;
@property (nonatomic,assign) BOOL isPlaying;
//默认是WAV， YES
@property (nonatomic, assign) BOOL isWav;

- (instancetype)initQueueWithSampleRate:(int)sampleRate bitPerSample:(int)bitPerSample channel:(int)channel;

- (void)play;

- (void)stop;

@end
