//
//  XLSNetwork.h
//  TimeCloud
//
//

#import <Foundation/Foundation.h>

typedef void (^XLSNetworkCompletionBlock)(NSError *error, NSDictionary *rspJSONObject);
typedef void (^XLSNetworkCompletionHandlerBlock)(NSData *data, NSURLResponse *rsp, NSError *error);

@interface XLSNetwork : NSObject
@property (nonatomic, readonly) NSURLSessionDataTask *currentTask;


- (BOOL)postWithJSONObject:(NSDictionary *)reqJSONObject
             hostURLString:(NSString *)url
              prepare:(void(^)(NSMutableURLRequest *request))prepareBlock
                completion:(XLSNetworkCompletionBlock)completion;

- (void)getWithURLString:(NSString *)url
              completion:(XLSNetworkCompletionBlock)completion;

- (void)getWithURLString:(NSString *)url
       completionHandler:(XLSNetworkCompletionHandlerBlock)completionHandler;

@end
