//
//  AudioQueuePlayReact.m
//  ProRecorder
//
//  Created by west on 2018/8/18.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "AudioQueuePlayReact.h"
#import "AudioQueuePlay.h"
#import "AppDelegate.h"

@interface AudioQueuePlayReact ()<AudioQueuePlayQueueDelegate> {
  AudioQueuePlay *_player;
}

@end

@implementation AudioQueuePlayReact

RCT_EXPORT_MODULE(AudioPlayer);

+ (BOOL)requiresMainQueueSetup {
  return YES;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _player = ((AppDelegate *)[UIApplication sharedApplication].delegate).audioPlayer;
    [_player addObserver:self];
  }
  return self;
}

- (void)dealloc {
  [_player removeObserver:self];
}

- (NSArray<NSString *> *)supportedEvents {
  //在这里添加JS监听的事件名称
  return @[@"onAudioPlayDidStop", @"onAudioPlayProgressChanged"];
}

RCT_REMAP_METHOD(play,
                  filePath:(NSString *)filePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
  if (_player.isPlaying) {
    [_player stop];
  }
  _player.pcmFile = filePath;
  _player.isWav = [filePath hasSuffix:@".wav"];
  [_player play];
  resolve(@"");
}

RCT_REMAP_METHOD(stop,
                 resolver2:(RCTPromiseResolveBlock)resolve
                 rejecter2:(RCTPromiseRejectBlock)reject) {
  [_player stop];
}

- (void)audioPlay:(AudioQueuePlay *)audioPlay didPlayStart:(NSNumber *)t {
  
}

- (void)audioPlay:(AudioQueuePlay *)audioPlay didPlayStop:(NSNumber *)t {
  NSDictionary *info = @{@"code":t};
  [self sendEventWithName:@"onAudioPlayDidStop" body:info];
}

- (void)audioPlay:(AudioQueuePlay *)audioPlay playData:(NSData *)data {
  
}

- (void)audioPlay:(AudioQueuePlay *)audioPlay playProgress:(NSNumber *)ms totalMs:(NSNumber *)totalMs {
  NSDictionary *info = @{@"progress":ms, @"total":totalMs};
  [self sendEventWithName:@"onAudioPlayProgressChanged" body:info];
}

@end
