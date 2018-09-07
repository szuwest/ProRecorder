//
//  XLSNetwork.m
//
//

#import "XLSNetwork.h"

@interface XLSNetwork ()
@property (nonatomic) float postTimeOutInterval;
@property (nonatomic) float getTimeOutInterval;

@property (nonatomic) NSURLSession *urlSession;

@end

@implementation XLSNetwork

//XL_IMPL_SHARED_INSTANCE(XLSNetwork)

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.postTimeOutInterval = 15.0;
        self.getTimeOutInterval = 15.0;
        self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
    return self;
}

- (XLSNetworkCompletionHandlerBlock)commonJSONCompletionHandlerWithCallback:(XLSNetworkCompletionBlock)completion
{
    XLSNetworkCompletionHandlerBlock block = ^(NSData *data, NSURLResponse *rsp, NSError *error) {
        if (error) {
            completion(error, nil);
        }
        else {
            NSError *failedError = [NSError errorWithDomain:@"XLSNetwork"
                                                       code:-1
                                                   userInfo:@{NSLocalizedDescriptionKey:@"Parse JSON failed!"}];
            NSError *error = nil;
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if (error || ![jsonObject isKindOfClass:[NSDictionary class]]) {
                completion(failedError, nil);
            }
            else {
                completion(nil, jsonObject);
            }
        }
    };
//    return [block copy];
    return block;
}

- (BOOL)postWithJSONObject:(NSDictionary *)reqJSONObject
             hostURLString:(NSString *)url
              prepare:(void(^)(NSMutableURLRequest *request))prepareBlock
                completion:(XLSNetworkCompletionBlock)completion
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.timeoutInterval = self.postTimeOutInterval;
    request.HTTPMethod = @"POST";
  
  if (prepareBlock != NULL) {
      prepareBlock(request);
  }
  
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:reqJSONObject
                                                       options:0
                                                         error:&error];
  request.HTTPBody = jsonData;
//  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
////  NSLog(@"jsonString = %@", jsonString);
//  jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\\" withString:@""];
//  NSLog(@"jsonString2 = %@", jsonString);
//  request.HTTPBody = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
  
    if (error) {
        return NO;
    }
    
    [self.currentTask cancel];
    _currentTask = [self.urlSession dataTaskWithRequest:request
                                      completionHandler:[self commonJSONCompletionHandlerWithCallback:completion]];
    [self.currentTask resume];
    
    return YES;
}

- (void)getWithURLString:(NSString *)url
              completion:(XLSNetworkCompletionBlock)completion
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.timeoutInterval = self.getTimeOutInterval;
    request.HTTPMethod = @"GET";
    [[self.urlSession dataTaskWithRequest:request
                       completionHandler:[self commonJSONCompletionHandlerWithCallback:completion]] resume];
}

- (void)getWithURLString:(NSString *)url
       completionHandler:(XLSNetworkCompletionHandlerBlock)completionHandler
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.timeoutInterval = self.getTimeOutInterval;
    request.HTTPMethod = @"GET";
    [[self.urlSession dataTaskWithRequest:request
                        completionHandler:completionHandler] resume];
}

@end
