//
//  AudioFileManager.h
//  record
//
//  Created by west on 2017/10/30.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTLog.h>

#define RECORDDIR @"ProRecorder"

@interface AudioFileManager : NSObject <RCTBridgeModule>

+ (NSString *)fileDirWithTeamId:(NSString *)teamId taskId:(NSString *)taskId;

+ (NSString *)fileDirWithTeamId:(NSString *)teamId taskId:(NSString *)taskId personIndex:(NSUInteger)personIndex;

+ (NSString *)fileDirWithTeamId:(NSString *)teamId taskId:(NSString *)taskId personIndex:(NSUInteger)personIndex voiceIndex:(NSUInteger)voiceIndex;

+ (void)deleteAudiosWithTeamId:(NSString *)teamId taskId:(NSString *)taskId personIndex:(NSUInteger)personIndex;

+ (void)deleteAudiosWithTeamId:(NSString *)teamId taskId:(NSString *)taskId personIndex:(NSUInteger)personIndex voiceIndex:(NSUInteger)voiceIndex;
+ (NSString*) pathInDocuments:(NSString*)path;
@end
