//
//  SIAudioHelper.m
//  SpeakinDemo
//
//  Created by west on 2017/8/16.
//  Copyright © 2017年 speakin. All rights reserved.
//

#import "SIAudioHelper.h"
#import <AVFoundation/AVFoundation.h>

@implementation SIAudioHelper

NSData* WriteWavFileHeader2(long totalAudioLen, long totalDataLen, long longSampleRate,int channels, int bitPerSample)
{
  long byteRate = longSampleRate * bitPerSample * channels / 8;
    Byte  header[44];
    header[0] = 'R';  // RIFF/WAVE header
    header[1] = 'I';
    header[2] = 'F';
    header[3] = 'F';
    header[4] = (Byte) (totalDataLen & 0xff);  //file-size (equals file-size - 8)
    header[5] = (Byte) ((totalDataLen >> 8) & 0xff);
    header[6] = (Byte) ((totalDataLen >> 16) & 0xff);
    header[7] = (Byte) ((totalDataLen >> 24) & 0xff);
    header[8] = 'W';  // Mark it as type "WAVE"
    header[9] = 'A';
    header[10] = 'V';
    header[11] = 'E';
    header[12] = 'f';  // Mark the format section 'fmt ' chunk
    header[13] = 'm';
    header[14] = 't';
    header[15] = ' ';
    header[16] = 16;   // 4 bytes: size of 'fmt ' chunk, Length of format data.  Always 16
    header[17] = 0;
    header[18] = 0;
    header[19] = 0;
    header[20] = 1;  // format = 1 ,Wave type PCM
    header[21] = 0;
    header[22] = (Byte) channels;  // channels
    header[23] = 0;
    header[24] = (Byte) (longSampleRate & 0xff);
    header[25] = (Byte) ((longSampleRate >> 8) & 0xff);
    header[26] = (Byte) ((longSampleRate >> 16) & 0xff);
    header[27] = (Byte) ((longSampleRate >> 24) & 0xff);
    header[28] = (Byte) (byteRate & 0xff);
    header[29] = (Byte) ((byteRate >> 8) & 0xff);
    header[30] = (Byte) ((byteRate >> 16) & 0xff);
    header[31] = (Byte) ((byteRate >> 24) & 0xff);
    header[32] = (Byte) (channels * bitPerSample / 8); // block align
    header[33] = 0;
    header[34] = bitPerSample; // bits per sample
    header[35] = 0;
    header[36] = 'd'; //"data" marker
    header[37] = 'a';
    header[38] = 't';
    header[39] = 'a';
    header[40] = (Byte) (totalAudioLen & 0xff);  //data-size (equals file-size - 44).
    header[41] = (Byte) ((totalAudioLen >> 8) & 0xff);
    header[42] = (Byte) ((totalAudioLen >> 16) & 0xff);
    header[43] = (Byte) ((totalAudioLen >> 24) & 0xff);
    return [[NSData alloc] initWithBytes:header length:44];
}

NSData* WriteWavFileHeader(long totalAudioLen, long longSampleRate,int channels, int bitPerSample) {
    return WriteWavFileHeader2(totalAudioLen, totalAudioLen+36, longSampleRate, channels, bitPerSample);
}

+ (NSString *)savePcmToWav:(NSString *)pcmFilePath withSample:(long)sampleRate bitPerSample:(int)bitPerSample channel:(int)channels{
    NSData *audioData = [NSData dataWithContentsOfFile:pcmFilePath];
    long audioLen = audioData.length;
    long totalLen = audioLen + 36;
//    int bitPerSample = 16;
//    int channels = 1;
    NSData *header = WriteWavFileHeader2(audioLen,totalLen,sampleRate,channels,bitPerSample);
    NSMutableData *wavDatas = [[NSMutableData alloc]init];
    [wavDatas appendData:header];
    
    [wavDatas appendData:audioData];
    NSString *fileName = [pcmFilePath lastPathComponent];
    fileName = [fileName stringByDeletingPathExtension];
    fileName = [fileName stringByAppendingPathExtension:@"wav"];
    NSString *wavPath = [pcmFilePath stringByDeletingLastPathComponent];
    wavPath = [wavPath stringByAppendingPathComponent:fileName];
    [wavDatas writeToFile:wavPath atomically:YES];
    
    return wavPath;
}

+ (BOOL)hasAudioAuthorization {
  AVAuthorizationStatus audioAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
  return (audioAuthStatus == AVAuthorizationStatusAuthorized) || (audioAuthStatus == AVAuthorizationStatusNotDetermined);
}

@end
