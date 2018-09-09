//
//  SIAudioInputQueue
//
//  Created by west on 2017/8/16.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "XLObserverHoster.h"

#define DEFAULT_SAMPLEREATE 16000

@class SIAudioInputQueue;
@protocol SIAudioInputQueueDelegate <NSObject>
@required
- (void)inputQueue:(SIAudioInputQueue *)inputQueue inputData:(NSData *)data numberOfPackets:(NSNumber *)numberOfPackets;
- (void)inputQueue:(SIAudioInputQueue *)inputQueue errorOccur:(NSError *)error;
@optional
- (void)inputQueue:(SIAudioInputQueue *)inputQueue didStop:(NSString *)audioSavePath;
- (void)inputQueueDidStart:(SIAudioInputQueue*)inputQueue;
@end

@interface SIAudioInputQueue : XLObserverHoster

//@property (nonatomic,weak) id<SIAudioInputQueueDelegate> delegate;
@property (nonatomic,copy) NSString *audioSavePath;//音频存储路径
@property (nonatomic,assign,readonly) BOOL available;
@property (nonatomic,assign,readonly) BOOL isRunning;
@property (atomic, assign, readonly) BOOL isCancel;
@property (nonatomic,assign,readonly) AudioStreamBasicDescription format;
@property (nonatomic,assign,readonly) NSTimeInterval bufferDuration;
@property (nonatomic,assign,readonly) UInt32 bufferSize;
@property (nonatomic,assign) BOOL meteringEnabled;

+ (AudioStreamBasicDescription)formatWithSampleRate:(int)sampleRate bitPerSample:(int)bitPerSample channel:(int)channel;
+ (instancetype)defaultInputQueue;
+ (instancetype)inputQueueWithSampleRate:(int)sampleRate bitPerSample:(int)bitPerSample channel:(int)channel;

- (BOOL)start;
- (BOOL)startWithSavePath:(NSString *)savePath format:(AudioStreamBasicDescription)format;
//- (BOOL)pause;
- (BOOL)stop;
//- (BOOL)reset;
- (void)cancel;

- (void)updateMeters; /* call to refresh meter values */
- (float)peakPowerForChannel:(NSUInteger)channelNumber; /* returns peak power in decibels for a given channel */
- (float)averagePowerForChannel:(NSUInteger)channelNumber; /* returns average power in decibels for a given channel */

@end
