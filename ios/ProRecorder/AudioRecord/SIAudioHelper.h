//
//  SIAudioHelper.h
//  SpeakinDemo
//
//  Created by west on 2017/8/16.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIAudioHelper : NSObject

NSData* WriteWavFileHeader(long totalAudioLen, long longSampleRate,int channels, int bitPerSample);

+ (NSString *)savePcmToWav:(NSString *)pcmFilePath withSample:(long)sampleRate bitPerSample:(int)bitPerSample channel:(int)channels;

+ (BOOL)hasAudioAuthorization;

@end
