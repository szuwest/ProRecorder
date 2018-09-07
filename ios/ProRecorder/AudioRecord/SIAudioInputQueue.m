//
//  SIAudioInputQueue
//
//  Created by west on 2017/8/16.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import "SIAudioInputQueue.h"
#import <AVFoundation/AVFoundation.h>

const int SIAudioQueueBufferCount = 3;

@interface SIAudioInputQueue ()
{
  AudioQueueRef _audioQueue;
  
  BOOL _started;
  BOOL _isRunning;
  UInt32 _bufferSize;
  NSMutableData *_buffer;
  
  AudioQueueLevelMeterState *_meterStateDB;
  //    NSOutputStream *_outPutStream;
  NSFileHandle *_fileHandler;
}

/**
 *  create input queue
 *
 *  @param format         audio format
 *  @param bufferDuration duration per buffer block
 *  @param delegate       delegate
 *
 *  @return input queue instance
 */
+ (instancetype)inputQueueWithFormat:(AudioStreamBasicDescription)format bufferDuration:(NSTimeInterval)bufferDuration;
@end

@implementation SIAudioInputQueue

#pragma mark - init & dealloc

+ (AudioStreamBasicDescription)formatWithSampleRate:(int)sampleRate bitPerSample:(int)bitPerSample channel:(int)channel {
  AudioStreamBasicDescription format;
  format.mFormatID = kAudioFormatLinearPCM;
  format.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
  format.mBitsPerChannel = bitPerSample;//采样位数
  format.mChannelsPerFrame = channel;///单声道
  format.mBytesPerPacket = format.mBytesPerFrame = (format.mBitsPerChannel / 8) * format.mChannelsPerFrame;
  format.mFramesPerPacket = 1;//每一个packet一侦数据
  format.mSampleRate = sampleRate;//采样率
  return format;
}

+ (instancetype)defaultInputQueue {
  AudioStreamBasicDescription format = [self formatWithSampleRate:DEFAULT_SAMPLEREATE bitPerSample:16 channel:1];
  return [[self class] inputQueueWithFormat:format bufferDuration:0.05];
}

+ (instancetype)inputQueueWithSampleRate:(int)sampleRate bitPerSample:(int)bitPerSample channel:(int)channel {
  AudioStreamBasicDescription format = [self formatWithSampleRate:sampleRate bitPerSample:bitPerSample channel:channel];
  return [[self class] inputQueueWithFormat:format bufferDuration:0.05];
}

+ (instancetype)inputQueueWithFormat:(AudioStreamBasicDescription)format bufferDuration:(NSTimeInterval)bufferDuration
{
  return [[self alloc] initWithFormat:format bufferDuration:bufferDuration];
}

- (instancetype)initWithFormat:(AudioStreamBasicDescription)format bufferDuration:(NSTimeInterval)bufferDuration
{
  if (bufferDuration <= 0)
  {
    return nil;
  }
  
  self = [super init];
  if (self)
  {
    _format = format;
    _bufferDuration = bufferDuration;
    
    //lenInByte = bitDepth * channelCount * samplerate * duration / 8;
    _bufferSize = _format.mBitsPerChannel * _format.mChannelsPerFrame * _format.mSampleRate * _bufferDuration / 8;
    _buffer = [[NSMutableData alloc] init];
    if (_meterStateDB != nil) {
      free(_meterStateDB);
    }
    _meterStateDB = (AudioQueueLevelMeterState *)malloc(sizeof(AudioQueueLevelMeterState) * _format.mChannelsPerFrame);
    
    //        [self _createAudioInputQueue];
    //        [self _updateMeteringEnabled];
  }
  return self;
}


- (void)dealloc
{
  free(_meterStateDB);
  if (_audioQueue != NULL) {
    [self stop];
  }
}

#pragma mark - error
- (void)_errorForOSStatus:(OSStatus)status error:(NSError *__autoreleasing *)outError
{
  if (status != noErr && outError != NULL)
  {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
  }
}

- (BOOL)_checkAudioQueueSuccess:(OSStatus)status
{
  if (status != noErr)
  {
    if (_audioQueue)
    {
      AudioQueueDispose(_audioQueue, YES);
      _audioQueue = NULL;
    }
    NSError *error = nil;
    [self _errorForOSStatus:status error:&error];
    [self notifyObservers:@selector(inputQueue:errorOccur:) withObjects:self, error,nil];
//    [_delegate inputQueue:self errorOccur:error];
    return NO;
  }
  return YES;
}

#pragma mark - audio queue
- (void)_createAudioInputQueue
{
  if (![self _checkAudioQueueSuccess:AudioQueueNewInput(&_format, MCAudioQueueInuputCallback, (__bridge void *)(self), NULL, NULL, 0, &_audioQueue)])
  {
    return;
  }
  
  AudioQueueAddPropertyListener(_audioQueue, kAudioQueueProperty_IsRunning, MCAudioInputQueuePropertyCallback, (__bridge void *)(self));
  
  for (int i = 0; i < SIAudioQueueBufferCount; ++i)
  {
    AudioQueueBufferRef buffer;
    if (![self _checkAudioQueueSuccess:AudioQueueAllocateBuffer(_audioQueue, _bufferSize, &buffer)])
    {
      break;
    }
    
    if (![self _checkAudioQueueSuccess:AudioQueueEnqueueBuffer(_audioQueue, buffer, 0, NULL)])
    {
      break;
    }
  }
}

- (BOOL)start
{
  if ([self isRunning]) {
    NSLog(@"is recording already");
    return false;
  }
  AVAudioSession *audioSession = [AVAudioSession sharedInstance];
  NSError *error;
  [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
  if (error) {
    NSLog(@"error = %@", error);
  }
  [audioSession setActive:YES error:&error];
  if (error) {
    NSLog(@"error = %@", error);
  }
  [self _createAudioInputQueue];
  [self _updateMeteringEnabled];
  OSStatus status = AudioQueueStart(_audioQueue, NULL);
  _started = status == noErr;
  if (_started) {
    [self notifyObservers:@selector(inputQueueDidStart:) withObject:self];
  }
  return _started;
}

- (BOOL)startWithSavePath:(NSString *)savePath format:(AudioStreamBasicDescription)format{
  if ([self isRunning]) {
    NSLog(@"is recording already");
    return false;
  }
  self.audioSavePath = savePath;
  
  _format = format;
  //lenInByte = bitDepth * channelCount * samplerate * duration / 8;
  _bufferSize = _format.mBitsPerChannel * _format.mChannelsPerFrame * _format.mSampleRate * _bufferDuration / 8;
  if (_meterStateDB != nil) {
    free(_meterStateDB);
  }
  _meterStateDB = (AudioQueueLevelMeterState *)malloc(sizeof(AudioQueueLevelMeterState) * _format.mChannelsPerFrame);
  
  return [self start];
}

- (BOOL)pause
{
  OSStatus status = AudioQueuePause(_audioQueue);
  return status == noErr;
}

- (BOOL)reset
{
  OSStatus status = AudioQueueReset(_audioQueue);
  return status == noErr;
}

- (BOOL)stop
{
  if (_audioQueue == NULL) {
    return YES;
  }
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setActive:NO error:nil];
  });
  
  _started = NO;
  OSStatus status = AudioQueueStop(_audioQueue, true);
  
  AudioQueueDispose(_audioQueue,true);
  _audioQueue = NULL;
  __weak SIAudioInputQueue *weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [weakSelf closeFile];
  });
  return status == noErr;
}

- (BOOL)available
{
  return _audioQueue != NULL;
}

#pragma mark - metering
- (void)_updateMeteringEnabled
{
  UInt32 size = sizeof(UInt32);
  UInt32 enabledLevelMeter = 0;
  [self getProperty:kAudioQueueProperty_EnableLevelMetering dataSize:&size data:&enabledLevelMeter error:nil];
  _meteringEnabled = enabledLevelMeter == 0 ? NO : YES;
}

- (void)setMeteringEnabled:(BOOL)meteringEnabled
{
  _meteringEnabled = meteringEnabled;
  UInt32 enabledLevelMeter = _meteringEnabled ? 1 : 0;
  [self setProperty:kAudioQueueProperty_EnableLevelMetering dataSize:sizeof(UInt32) data:&enabledLevelMeter error:nil];
}

- (void)updateMeters
{
  UInt32 size = sizeof(AudioQueueLevelMeterState) * _format.mChannelsPerFrame;
  [self getProperty:kAudioQueueProperty_CurrentLevelMeterDB dataSize:&size data:_meterStateDB error:nil];
}

- (float)peakPowerForChannel:(NSUInteger)channelNumber
{
  if (channelNumber >= _format.mChannelsPerFrame)
  {
    return -160.0f;
  }
  return _meterStateDB[channelNumber].mPeakPower;
}

- (float)averagePowerForChannel:(NSUInteger)channelNumber
{
  if (channelNumber >= _format.mChannelsPerFrame)
  {
    return -160.0f;
  }
  return _meterStateDB[channelNumber].mAveragePower;
}

#pragma mark - property & paramters
- (BOOL)setProperty:(AudioQueuePropertyID)propertyID dataSize:(UInt32)dataSize data:(const void *)data error:(NSError *__autoreleasing *)outError
{
  OSStatus status = AudioQueueSetProperty(_audioQueue, propertyID, data, dataSize);
  [self _errorForOSStatus:status error:outError];
  return status == noErr;
}

- (BOOL)getProperty:(AudioQueuePropertyID)propertyID dataSize:(UInt32 *)dataSize data:(void *)data error:(NSError *__autoreleasing *)outError
{
  OSStatus status = AudioQueueGetProperty(_audioQueue, propertyID, data, dataSize);
  [self _errorForOSStatus:status error:outError];
  return status == noErr;
}

- (BOOL)getPropertySize:(AudioQueuePropertyID)propertyID dataSize:(UInt32 *)dataSize error:(NSError *__autoreleasing *)outError
{
  OSStatus status = AudioQueueGetPropertySize(_audioQueue, propertyID, dataSize);
  [self _errorForOSStatus:status error:outError];
  return status == noErr;
}

- (BOOL)setParameter:(AudioQueueParameterID)parameterId value:(AudioQueueParameterValue)value error:(NSError *__autoreleasing *)outError
{
  OSStatus status = AudioQueueSetParameter(_audioQueue, parameterId, value);
  [self _errorForOSStatus:status error:outError];
  return status == noErr;
}

- (BOOL)getParameter:(AudioQueueParameterID)parameterId value:(AudioQueueParameterValue *)value error:(NSError *__autoreleasing *)outError
{
  OSStatus status = AudioQueueGetParameter(_audioQueue, parameterId, value);
  [self _errorForOSStatus:status error:outError];
  return status == noErr;
}

#pragma mark - call back
static void MCAudioQueueInuputCallback(void *inClientData,
                                       AudioQueueRef inAQ,
                                       AudioQueueBufferRef inBuffer,
                                       const AudioTimeStamp *inStartTime,
                                       UInt32 inNumberPacketDescriptions,
                                       const AudioStreamPacketDescription *inPacketDescs)
{
  SIAudioInputQueue *audioOutputQueue = (__bridge SIAudioInputQueue *)inClientData;
  [audioOutputQueue handleAudioQueueOutputCallBack:inAQ
                                            buffer:inBuffer
                                       inStartTime:inStartTime
                        inNumberPacketDescriptions:inNumberPacketDescriptions
                                     inPacketDescs:inPacketDescs];
}

- (void)handleAudioQueueOutputCallBack:(AudioQueueRef)audioQueue
                                buffer:(AudioQueueBufferRef)buffer
                           inStartTime:(const AudioTimeStamp *)inStartTime
            inNumberPacketDescriptions:(UInt32)inNumberPacketDescriptions
                         inPacketDescs:(const AudioStreamPacketDescription *)inPacketDescs
{
  if (_started)
  {
    [_buffer appendBytes:buffer->mAudioData length:buffer->mAudioDataByteSize];
    if (self.audioSavePath) {
      __block NSData *data = [[NSData alloc] initWithBytes:buffer->mAudioData length:buffer->mAudioDataByteSize];
//      dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self appendData:data];
//      });
    }
    if ([_buffer length] >= _bufferSize)
    {
      NSRange range = NSMakeRange(0, _bufferSize);
      NSData *subData = [_buffer subdataWithRange:range];
//      [_delegate inputQueue:self inputData:subData numberOfPackets:inNumberPacketDescriptions];
      [self notifyObservers:@selector(inputQueue:inputData:numberOfPackets:) withObjects:self, subData, @(inNumberPacketDescriptions), nil];
      [_buffer replaceBytesInRange:range withBytes:NULL length:0];
    }
    [self _checkAudioQueueSuccess:AudioQueueEnqueueBuffer(_audioQueue, buffer, 0, NULL)];
  }
}

- (void)handleAudioQueuePropertyCallBack:(AudioQueueRef)audioQueue property:(AudioQueuePropertyID)property
{
  if (property == kAudioQueueProperty_IsRunning)
  {
    UInt32 isRunning = 0;
    UInt32 size = sizeof(isRunning);
    AudioQueueGetProperty(audioQueue, property, &isRunning, &size);
    _isRunning = isRunning;
  }
}

static void MCAudioInputQueuePropertyCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
  __unsafe_unretained SIAudioInputQueue *audioQueue = (__bridge SIAudioInputQueue *)inUserData;
  [audioQueue handleAudioQueuePropertyCallBack:inAQ property:inID];
}

#pragma mark - write

- (void)appendData:(NSData *)data {
  if (!self.audioSavePath) {
    return;
  }
  if (!_fileHandler && ![[NSFileManager defaultManager] fileExistsAtPath:self.audioSavePath]) {
    //        [[NSFileManager defaultManager] createFileAtPath:self.audioSavePath contents:data attributes:nil];
    [data writeToFile:self.audioSavePath atomically:YES];
    return;
  } else {
    _fileHandler = [NSFileHandle fileHandleForWritingAtPath:self.audioSavePath];
    [_fileHandler seekToEndOfFile];
  }
  [_fileHandler writeData:data];
}

- (void)closeFile {
  if (_fileHandler != nil) {
    [_fileHandler synchronizeFile];
    [_fileHandler closeFile];
  }
  _fileHandler = nil;
//  if ([self.delegate respondsToSelector:@selector(inputQueue:didStop:)]) {
//    [self.delegate inputQueue:self didStop:self.audioSavePath];
//  }
  [self notifyObservers:@selector(inputQueue:didStop:) withObjects:self, self.audioSavePath, nil];
  self.audioSavePath = nil;
}

@end

