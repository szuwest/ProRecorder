//
//  SIUDID.m
//  VprScene
//
//  Created by west on 2018/3/29.
//  Copyright © 2018年 Facebook. All rights reserved.
//

#import "SIUDID.h"
#import <UIKit/UIKit.h>

NSString *const kUUIDKey = @"kUUIDKey_VPR";
NSString *const KEYCHAIN_SERVICE = @"KEYCHAIN_SERVICE_VPR";
NSString *const KEYCHAIN_ACCOUNT = @"KEYCHAIN_ACCOUNT_VPR";


@implementation SIUDID

+ (NSString *)getUUID{
  //  return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
  NSString *UUID = [[NSUserDefaults standardUserDefaults] objectForKey:kUUIDKey];
  
  if (UUID == nil || [UUID isEqualToString:@""] || UUID.length == 0) {
    UUID = [SSKeychain passwordForService:KEYCHAIN_SERVICE account:KEYCHAIN_ACCOUNT];
    NSError *error=nil;
    
    if (UUID == nil || [UUID isEqualToString:@""] || UUID.length == 0){
      NSLog(@"sskeychain none");
      UUID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
      [SSKeychain setPassword:UUID forService:KEYCHAIN_SERVICE account:KEYCHAIN_ACCOUNT error:&error];
      [[NSUserDefaults standardUserDefaults] setObject:UUID forKey:kUUIDKey];
      [[NSUserDefaults standardUserDefaults] synchronize];
      return UUID;
    }
    else {
      NSLog(@"sskeychain had");
      [[NSUserDefaults standardUserDefaults] setObject:UUID forKey:kUUIDKey];
      [[NSUserDefaults standardUserDefaults] synchronize];
      return UUID;
    }
  }
  else {
    return UUID;
  }
}


@end
