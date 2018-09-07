//
//  NSObject+XL.h
//  XL
//
//

#import <Foundation/Foundation.h>
//#import "XLCommonDefs.h"

#pragma mark - Category

@interface NSObject (XL)

+ (void)listenToRecycledEventOfObject:(id)object
                      recycledHandler:(dispatch_block_t)recycledHandler;

- (void)performBlock:(dispatch_block_t)block afterDelay:(NSTimeInterval)delay;
- (void)performBlockLater:(dispatch_block_t)block;

- (void)syncBlockInMainQueue:(dispatch_block_t)block;
- (void)asyncBlockInMainQueue:(dispatch_block_t)block;

- (void)asyncBlockInNewQueue:(dispatch_block_t)block;

// perform a block only once unless the App is uninstalled
- (void)performOnlyOnceForAppWithKey:(NSString *)key
                               block:(dispatch_block_t)block;

// perform a block only once for this object
- (void)performOnlyOnceForThisObjectWithKey:(NSString *)key
                                      block:(dispatch_block_t)block;

// Advance Skill：Hook methods in a class
+ (BOOL)hookInstanceMethodForClass:(__unsafe_unretained Class)targetClass
                    originalMethod:(SEL)originalMethod
                         newMethod:(SEL)newMethod;
+ (BOOL)unhookInstanceMethodForClass:(__unsafe_unretained Class)targetClass
                      originalMethod:(SEL)originalMethod
                           newMethod:(SEL)newMethod;

+ (BOOL)hookClassMethodForClass:(__unsafe_unretained Class)targetClass
                 originalMethod:(SEL)originalMethod
                      newMethod:(SEL)newMethod;
+ (BOOL)unhookClassMethodForClass:(__unsafe_unretained Class)targetClass
                   originalMethod:(SEL)originalMethod
                        newMethod:(SEL)newMethod;

- (BOOL)isNSNull;

+ (BOOL)containsInstanceMethod:(SEL)selector;
- (BOOL)containsInstanceMethod:(SEL)selector;
+ (BOOL)containsClassMethod:(SEL)selector;
- (BOOL)containsClassMethod:(SEL)selector;

- (BOOL)respondsToSelector:(SEL)selector excludingRootClass:(Class)rootClass;

- (NSString *)objectAddressString;

// Set an object as a property with a key
- (void)setAssociatedObject:(id)object withKey:(NSString *)key; // strong nonatomic
- (void)setAssociatedObject:(id)object withKey:(NSString *)key policyArray:(NSArray *)array;
- (void)removeAssociatedObjectWithKey:(NSString *)key;
- (id)associatedObjectWithKey:(NSString *)key;
+ (void)setAssociatedObject:(id)object withKey:(NSString *)key; // strong nonatomic
+ (void)setAssociatedObject:(id)object withKey:(NSString *)key policyArray:(NSArray *)array;
+ (void)removeAssociatedObjectWithKey:(NSString *)key;
+ (id)associatedObjectWithKey:(NSString *)key;

// The key is the objectAddressString of the object
- (void)setAssociatedObject:(id)object;
- (void)removeAssociatedObject:(id)object;
- (BOOL)isAssociatedWithObject:(id)object;
+ (void)setAssociatedObject:(id)object;
+ (void)removeAssociatedObject:(id)object;
+ (BOOL)isAssociatedWithObject:(id)object;

- (void)printSelf;
- (void)printSelfAddress;

@end

#pragma mark - C Functions

BOOL NSObjectIsEqual(NSObject *obj, NSObject *otherObj);
BOOL ProtocolContainsMethod(Protocol *aProtocol, SEL aSelector);

