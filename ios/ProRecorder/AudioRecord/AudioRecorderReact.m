//  Created by west on 2017/8/16.
//  Copyright © 2017年 speakin. All rights reserved.

#import <AVFoundation/AVFoundation.h>

#include <sys/sysctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <net/if_dl.h>
#import "SIUDID.h"
#import "AudioRecorderReact.h"
#import "SIAudioInputQueue.h"
#import "SIAudioHelper.h"
#import "AppDelegate.h"
#import "AudioFileManager.h"

@interface AudioRecorderReact() <SIAudioInputQueueDelegate> {
  RCTPromiseResolveBlock _stopResolve;
  RCTPromiseRejectBlock _stopReject;
}

@property (nonatomic, strong) SIAudioInputQueue *record;
@property (nonatomic, copy) NSString *currentVoicePath;
@property (nonatomic, assign) UInt64 dataLen;

@end

@implementation AudioRecorderReact

- (id)init{
  self = [super init];
//  self.record = [SIAudioInputQueue defaultInputQueue];
//  self.record.delegate = self;
  self.record = ((AppDelegate *)[UIApplication sharedApplication].delegate).audioRecorder;
  [self.record addObserver:self];
  NSString *docsDir = [AudioFileManager pathInDocuments:RECORDDIR];
  [[NSFileManager defaultManager] createDirectoryAtPath:docsDir withIntermediateDirectories:YES attributes:nil error:nil];
  return self;
}

- (void)dealloc {
  [self.record removeObserver:self];
}

RCT_EXPORT_MODULE(AudioRecorder);

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

- (NSArray<NSString *> *)supportedEvents
{
  //在这里添加JS监听的事件名称
  return @[@"onAudioError"];
}

//获取设备唯一标识
RCT_REMAP_METHOD(getIMEI,
                   resolver:(RCTPromiseResolveBlock)resolve
                   rejecter:(RCTPromiseRejectBlock)reject)
{
  NSLog(@"getIMEI=%@", [SIUDID getUUID]);
  resolve([SIUDID getUUID]);
}

//获取当前录音数据大小
RCT_REMAP_METHOD(getDataLength,
                 resolver1:(RCTPromiseResolveBlock)resolve
                 rejecter1:(RCTPromiseRejectBlock)reject)
{
  resolve([NSString stringWithFormat:@"%lld",self.dataLen]);
}

//检查当前是否开启录音权限
RCT_REMAP_METHOD(checkAndRequestAudio,
                 resolver5:(RCTPromiseResolveBlock)resolve
                 rejecter5:(RCTPromiseRejectBlock)reject)
{
  AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
  if (audioAuthStatus == AVAuthorizationStatusDenied) {
    reject(@"-1",@"未开启麦克风访问权限，无法进行录音，请先到【设置】App开启麦克风访问权限",nil);
    return;
  }
  [self.record start];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.record stop];
    resolve(NULL);
  });
}

//开始录音
RCT_REMAP_METHOD( startRecord,
                  resolver2:(RCTPromiseResolveBlock)resolve
                  rejecter2:(RCTPromiseRejectBlock)reject)
{
  NSLog(@"startAudioRecording");
  AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
  if (audioAuthStatus == AVAuthorizationStatusDenied) {
    reject(@"-1",@"未开启麦克风访问权限，无法进行录音，请先到【设置】App开启麦克风访问权限",nil);
    return;
  }
  
  if (self.record.isRunning) {
    resolve(NULL);
    return;
  }
  
  self.currentVoicePath = [self createSavePath];
  self.record.audioSavePath = self.currentVoicePath;
  BOOL succ = [self.record start];
  self.dataLen = 0;
  if(succ){
    resolve(NULL);
  } else {
    reject(@"-1",@"录音失败，请检查录音权限是否已开启",nil);
  }
}

RCT_REMAP_METHOD(startRecord2,
                   sampleRate:(int)sampleRate
                   bitPerSample:(int)bitPerSample
                   channel:(int)channel
                 resolver2:(RCTPromiseResolveBlock)resolve
                 rejecter2:(RCTPromiseRejectBlock)reject)
{
  NSLog(@"startAudioRecording");
  AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
  if (audioAuthStatus == AVAuthorizationStatusDenied) {
    reject(@"-1",@"未开启麦克风访问权限，无法进行录音，请先到【设置】App开启麦克风访问权限",nil);
    return;
  }
  
  if (self.record.isRunning) {
    resolve(NULL);
    return;
  }
  
  self.currentVoicePath = [self createSavePath];
  AudioStreamBasicDescription format = [SIAudioInputQueue formatWithSampleRate:sampleRate bitPerSample:bitPerSample channel:channel];
  BOOL succ = [self.record startWithSavePath:self.currentVoicePath format:format];
  self.dataLen = 0;
  if(succ){
    resolve(NULL);
  } else {
    reject(@"-1",@"录音失败，请检查录音权限是否已开启",nil);
  }
}

//结束录音
RCT_REMAP_METHOD(stopRecord,
                  resolver3:(RCTPromiseResolveBlock)resolve
                  rejecter3:(RCTPromiseRejectBlock)reject)
{
  if (!self.record.isRunning) {
    reject(@"fail",@"not start",nil);
    return;
  }
  _stopResolve = resolve;
  _stopReject = reject;
  NSLog(@"stopAudioRecording path=%@", self.currentVoicePath);

  [self.record stop];
}

RCT_REMAP_METHOD(cancelRecording,
                 resolver4:(RCTPromiseResolveBlock)resolve
                 rejecter5:(RCTPromiseRejectBlock)reject)
{
  if (!self.record.isRunning) {
    resolve(NULL);
    return;
  }
  NSLog(@"stopAudioRecording path=%@", self.currentVoicePath);
  [self.record cancel];
  resolve(NULL);
}
#pragma mark -

- (void)inputQueue:(SIAudioInputQueue *)inputQueue inputData:(NSData *)data numberOfPackets:(NSNumber *)numberOfPackets {
  self.dataLen += data.length;
}

- (void)inputQueue:(SIAudioInputQueue *)inputQueue errorOccur:(NSError *)error {
  NSLog(@"error = %@", error);
  [self.record stop];
  NSDictionary *errInfo = @{@"errCode": [NSNumber numberWithInteger:error.code], @"errMsg":error.localizedDescription};
  [self sendEventWithName:@"onAudioError" body:errInfo];
  _stopResolve = NULL;
  _stopReject = NULL;
}

- (void)inputQueue:(SIAudioInputQueue *)inputQueue didStop:(NSString *)audioSavePath {
  NSLog(@"didStop");
  if (inputQueue.isCancel) {
    return;
  }
  if (audioSavePath && _stopResolve != NULL) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
      NSString *wavPath = [SIAudioHelper savePcmToWav:audioSavePath withSample:inputQueue.format.mSampleRate bitPerSample:inputQueue.format.mBitsPerChannel channel:inputQueue.format.mChannelsPerFrame];
      self.currentVoicePath = wavPath;
      _stopResolve(self.currentVoicePath);
      _stopResolve = NULL;
      _stopReject = NULL;
    });
  }
}

- (NSString *)createSavePath {
  NSString *docsDir = [AudioFileManager pathInDocuments:RECORDDIR];
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  formatter.dateFormat = @"yyyyMMdd_HH:mm:ss";
  NSString *dateString = [formatter stringFromDate:[NSDate date]];
  NSString *voiceFileName = [NSString stringWithFormat:@"%@.pcm", dateString];
  return [docsDir stringByAppendingPathComponent:voiceFileName];
}

@end
