//
//  AudioFileManager.m
//  record
//
//  Created by west on 2017/10/30.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "AudioFileManager.h"

@implementation AudioFileManager

RCT_EXPORT_MODULE(AudioFileManager)

RCT_REMAP_METHOD(deleteFile,
                 filePath:(NSString *)filePath
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) {
      reject([NSString stringWithFormat:@"%ld",(long)error.code], error.localizedDescription,nil);
    } else {
      resolve(nil);
    }
  });
}

RCT_REMAP_METHOD(deleteFiles,
                 filesArray:(NSArray *)filesArray
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSError *error = nil;
    for (NSString *filePath in filesArray) {
      NSError *err = nil;
      [[NSFileManager defaultManager] removeItemAtPath:filePath error:&err];
      if (err) {
        error = err;
      }
    }
    if (error) {
      reject([NSString stringWithFormat:@"%ld",(long)error.code], error.localizedDescription,nil);
    } else {
      resolve(nil);
    }
  });
}

RCT_REMAP_METHOD(listFileInDoc,
                 pathInDoc:(NSString *)pathInDoc
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  NSString *filePath = [[self class] pathInDocuments:pathInDoc];
  NSLog(@"path=%@", filePath);
  NSFileManager * fileManger = [NSFileManager defaultManager];
  BOOL isDir = NO;
  NSMutableArray *pathList = [NSMutableArray new];
  BOOL isExist = [fileManger fileExistsAtPath:filePath isDirectory:&isDir];
  if (isExist) {
    if (isDir) {
      NSArray * dirArray = [fileManger contentsOfDirectoryAtPath:filePath error:nil];
      NSString * subPath = nil;
      for (NSString * str in dirArray) {
        subPath  = [filePath stringByAppendingPathComponent:str];
        NSLog(@"path=%@", subPath);
        if ([str.lowercaseString hasSuffix:@".wav"]) {
          [pathList addObject:subPath];
        }
      }
    }
  }
  resolve(pathList);
}

RCT_REMAP_METHOD(deletePersonAudioDir,
                  teamId:(NSString *)teamId
                  taskId:(NSString *)taskId
                  personIndex:(NSInteger)personIndex
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSString *filePath = [[self class] fileDirWithTeamId:teamId taskId:taskId personIndex:personIndex];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) {
      reject([NSString stringWithFormat:@"%ld",(long)error.code], error.localizedDescription,nil);
    } else {
      resolve(nil);
    }
  });
}

RCT_REMAP_METHOD(deleteTaskFiles,
                 teamId:(NSString *)teamId
                 taskId:(NSString *)taskId
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
  dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSString *filePath = [[self class] fileDirWithTeamId:teamId taskId:taskId];
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) {
      reject([NSString stringWithFormat:@"%ld",(long)error.code], error.localizedDescription,nil);
    } else {
      resolve(nil);
    }
  });
}

+ (NSString *)fileDirWithTeamId:(NSString *)teamId taskId:(NSString *)taskId {
  return [self pathInDocuments:[NSString stringWithFormat:@"%@/%@/", teamId, taskId]];
}

+ (NSString *)fileDirWithTeamId:(NSString *)teamId taskId:(NSString *)taskId personIndex:(NSUInteger)personIndex {
  NSString *filePath = [self fileDirWithTeamId:teamId taskId:taskId];
  return [filePath stringByAppendingString:[NSString stringWithFormat:@"%ld/", personIndex]];
}

+ (NSString *)fileDirWithTeamId:(NSString *)teamId taskId:(NSString *)taskId personIndex:(NSUInteger)personIndex voiceIndex:(NSUInteger)voiceIndex {
  NSString *filePath = [self fileDirWithTeamId:teamId taskId:taskId personIndex:personIndex];
  filePath = [filePath stringByAppendingFormat:@"%ld/", voiceIndex];
  if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
  }
  return filePath;
}

+ (void)deleteAudiosWithTeamId:(NSString *)teamId taskId:(NSString *)taskId personIndex:(NSUInteger)personIndex {
  NSString *filePath = [self fileDirWithTeamId:teamId taskId:taskId personIndex:personIndex];
  [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}

+ (void)deleteAudiosWithTeamId:(NSString *)teamId taskId:(NSString *)taskId personIndex:(NSUInteger)personIndex voiceIndex:(NSUInteger)voiceIndex {
  NSString *filePath = [self fileDirWithTeamId:teamId taskId:taskId personIndex:personIndex voiceIndex:voiceIndex];
  [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}

+ (NSString*) pathInDocuments:(NSString*)path {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* path0 = paths[0];
  return path ? [path0 stringByAppendingPathComponent:path] : path0;
}

@end
