/**
 * Copyright (c) 2015-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <UIKit/UIKit.h>
#import "SIAudioInputQueue.h"
#import "AudioQueuePlay.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong, readonly) SIAudioInputQueue *audioRecorder;
@property (nonatomic, strong, readonly) AudioQueuePlay *audioPlayer;

@end
