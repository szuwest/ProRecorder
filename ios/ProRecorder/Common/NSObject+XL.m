//
//  NSObject+XL.m
//  XL
//
//  Created by LINQIUMING on 5/31/15.
//  Copyright (c) 2015 LINQIUMING. All rights reserved.
//

#import "NSObject+XL.h"
#import <objc/runtime.h>

#pragma mark - XLObjectRecycledListener
@interface XLObjectRecycledListener : NSObject
@property (strong, nonatomic) dispatch_block_t recycledHandler;
+ (void)listenToObject:(id)object
       recycledHandler:(dispatch_block_t)recycledHandler;
@end
@implementation XLObjectRecycledListener
+ (void)listenToObject:(id)object recycledHandler:(dispatch_block_t)recycledHandler
{
    XLObjectRecycledListener *listener = [[XLObjectRecycledListener alloc] init];
    listener.recycledHandler = recycledHandler;
    [object setAssociatedObject:listener];
}
- (void)dealloc
{
    self.recycledHandler();
}
@end

#pragma mark - XLClassHookedInfo
typedef NS_ENUM(NSInteger, XLClassHookedType) {
    XLClassHookedType_Unhooked  = 0,
    XLClassHookedType_HookedByExchange,
    XLClassHookedType_HookedByAddingMethod
};
@interface XLClassHookedInfoItem : NSObject
@property (nonatomic, readonly) SEL originalSelector;
@property (nonatomic, readonly) NSMutableArray *hookedSelectorChain;
@property (nonatomic, readonly) XLClassHookedType hookedType;
- (BOOL)isSelectorHooked:(SEL)selector;
- (void)hookWithSelector:(SEL)selector hookedType:(XLClassHookedType)hookedType;
- (void)unhookWithSelector:(SEL)selector;
@end
@implementation XLClassHookedInfoItem
- (instancetype)initWithOrginalSelector:(SEL)originalSelector
{
    self = [super init];
    if (self) {
        _originalSelector = originalSelector;
        _hookedSelectorChain = [NSMutableArray new];
    }
    return self;
}
- (BOOL)isSelectorHooked:(SEL)selector
{
    return [self.hookedSelectorChain containsObject:NSStringFromSelector(selector)];
}
- (void)hookWithSelector:(SEL)selector hookedType:(XLClassHookedType)hookedType
{
    if ([self isSelectorHooked:selector]) {
        return ;
    }
    if (self.hookedSelectorChain.count == 0) {
        _hookedType = hookedType;
    }
    [self.hookedSelectorChain insertObject:NSStringFromSelector(selector) atIndex:0];
}
- (void)unhookWithSelector:(SEL)selector
{
    if ([self isSelectorHooked:selector]) {
        [self.hookedSelectorChain removeObject:NSStringFromSelector(selector)];
        
        if (self.hookedSelectorChain.count == 0) {
            _hookedType = XLClassHookedType_Unhooked;
        }
    }
}
- (SEL)preSelectorOfSelector:(SEL)selector
{
    NSInteger index = [self.hookedSelectorChain indexOfObject:NSStringFromSelector(selector)];
    if (index == NSNotFound) {
        return nil;
    }
    if (index > 0) {
        return NSSelectorFromString(self.hookedSelectorChain[index-1]);
    }
    return _originalSelector;
}
@end

@interface XLClassHookedInfo : NSObject
@property (nonatomic, strong, readonly) NSArray *items;
- (XLClassHookedInfoItem *)itemForOrginalSelector:(SEL)originalSelector;
- (void)removeItemForOriginalSelector:(SEL)originalSelector;
@end
@implementation XLClassHookedInfo
- (instancetype)init
{
    self = [super init];
    if (self) {
        _items = [NSMutableArray new];
    }
    return self;
}
- (XLClassHookedInfoItem *)itemForOrginalSelector:(SEL)originalSelector
{
    for (XLClassHookedInfoItem *item in self.items) {
        if (item.originalSelector == originalSelector) {
            return item;
        }
    }
    XLClassHookedInfoItem *item = [[XLClassHookedInfoItem alloc] initWithOrginalSelector:originalSelector];
    [(NSMutableArray *)self.items addObject:item];
    return item;
}
- (void)removeItemForOriginalSelector:(SEL)originalSelector
{
    for (XLClassHookedInfoItem *item in self.items) {
        if (item.originalSelector == originalSelector) {
            [(NSMutableArray *)self.items removeObject:item];
            break;
        }
    }
}
@end

#pragma mark - Category

@implementation NSObject (XL)

+ (void)listenToRecycledEventOfObject:(id)object
                      recycledHandler:(dispatch_block_t)recycledHandler
{
    [XLObjectRecycledListener listenToObject:object recycledHandler:recycledHandler];
}

- (void)XL_fireBlock:(dispatch_block_t)block
{
    block();
}

- (void)performBlock:(dispatch_block_t)block afterDelay:(NSTimeInterval)delay
{
    block = [block copy];
    
    [self performSelector:@selector(XL_fireBlock:)
               withObject:block
               afterDelay:delay];
}

- (void)performBlockLater:(dispatch_block_t)block
{
    block = [block copy];
    
    [self performSelector:@selector(XL_fireBlock:)
               withObject:block
               afterDelay:0];
}

- (void)syncBlockInMainQueue:(dispatch_block_t)block
{
    block = [block copy];
    
    [self performSelectorOnMainThread:@selector(XL_fireBlock:)
                           withObject:block
                        waitUntilDone:YES];
}
- (void)asyncBlockInMainQueue:(dispatch_block_t)block
{
    block = [block copy];
    
    [self performSelectorOnMainThread:@selector(XL_fireBlock:)
                           withObject:block
                        waitUntilDone:NO];
}

- (void)asyncBlockInNewQueue:(dispatch_block_t)block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

- (void)performOnlyOnceForAppWithKey:(NSString *)key
                               block:(dispatch_block_t)block
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL processed = [userDefaults boolForKey:key];
    if (!processed) {
        block();
        [userDefaults setBool:YES forKey:key];
        [userDefaults synchronize];
    }
}

- (void)performOnlyOnceForThisObjectWithKey:(NSString *)key
                                      block:(dispatch_block_t)block
{
    if (![self associatedObjectWithKey:key]) {
        [self setAssociatedObject:@(YES) withKey:key];
        block();
    }
}

+ (XLClassHookedInfo *)xlClassHookedInfo {
    XLClassHookedInfo *info = [self associatedObjectWithKey:@"xlClassHookedInfo"];
    if (!info) {
        info = [XLClassHookedInfo new];
        [self setAssociatedObject:info withKey:@"xlClassHookedInfo"];
    }
    return info;
}

+ (BOOL)hookInstanceMethodForClass:(__unsafe_unretained Class)targetClass
                        originalMethod:(SEL)originalMethod
                             newMethod:(SEL)newMethod
{
    XLClassHookedInfo *info = [targetClass xlClassHookedInfo];
    XLClassHookedInfoItem *item = [info itemForOrginalSelector:originalMethod];
    if ([item isSelectorHooked:newMethod]) {
        return YES;
    }
    
    Method mOrgMethod = class_getInstanceMethod(targetClass, originalMethod);
    if (!mOrgMethod) {
        return NO;
    }
    Method mNewMethod = class_getInstanceMethod(targetClass, newMethod);
    if (!mNewMethod) {
        return NO;
    }
    
    IMP impOrg = method_getImplementation(mOrgMethod);
    IMP impNew = method_getImplementation(mNewMethod);
    method_setImplementation(mNewMethod, impOrg);
    
    XLClassHookedType hookedType;
    
    if ([targetClass containsInstanceMethod:originalMethod])
    {
        method_setImplementation(mOrgMethod, impNew);
        
        hookedType = XLClassHookedType_HookedByExchange;
    }
    else {
        class_addMethod(targetClass, originalMethod, impNew, method_getTypeEncoding(mOrgMethod));
        
        hookedType = XLClassHookedType_HookedByAddingMethod;
    }
    
    [item hookWithSelector:newMethod hookedType:hookedType];
    
    return YES;
}

+ (BOOL)unhookInstanceMethodForClass:(__unsafe_unretained Class)targetClass
                      originalMethod:(SEL)originalMethod
                           newMethod:(SEL)newMethod
{
    XLClassHookedInfo *info = [targetClass xlClassHookedInfo];
    XLClassHookedInfoItem *item = [info itemForOrginalSelector:originalMethod];
    if (![item isSelectorHooked:newMethod]) {
        return NO;
    }
    
    SEL preSelector = [item preSelectorOfSelector:newMethod];
    if (!preSelector) {
        return NO;
    }
    
    Method mPreMethod = class_getInstanceMethod(targetClass, preSelector);
    if (!mPreMethod) {
        return NO;
    }
    Method mNewMethod = class_getInstanceMethod(targetClass, newMethod);
    if (!mNewMethod) {
        return NO;
    }
    
    IMP impPre = method_getImplementation(mPreMethod);
    IMP impNew = method_getImplementation(mNewMethod);
    method_setImplementation(mNewMethod, impPre);
    method_setImplementation(mPreMethod, impNew);
    
    [item unhookWithSelector:newMethod];
    
    return YES;
}

+ (BOOL)hookClassMethodForClass:(__unsafe_unretained Class)targetClass
                     originalMethod:(SEL)originalMethod
                          newMethod:(SEL)newMethod
{
    XLClassHookedInfo *info = [targetClass xlClassHookedInfo];
    XLClassHookedInfoItem *item = [info itemForOrginalSelector:originalMethod];
    if ([item isSelectorHooked:newMethod]) {
        return YES;
    }
    
    Method mOrgMethod = class_getClassMethod(targetClass, originalMethod);
    if (!mOrgMethod) {
        return NO;
    }
    Method mNewMethod = class_getClassMethod(targetClass, newMethod);
    if (!mNewMethod) {
        return NO;
    }

    IMP impOrg = method_getImplementation(mOrgMethod);
    IMP impNew = method_getImplementation(mNewMethod);
    method_setImplementation(mNewMethod, impOrg);
    
    XLClassHookedType hookedType;
    if ([targetClass containsClassMethod:originalMethod])
    {
        method_setImplementation(mOrgMethod, impNew);

        hookedType = XLClassHookedType_HookedByExchange;
    }
    else {
        class_addMethod(object_getClass(targetClass),
                        originalMethod,
                        impNew,
                        method_getTypeEncoding(mOrgMethod));
        
        hookedType = XLClassHookedType_HookedByAddingMethod;
    }
    
    [item hookWithSelector:newMethod hookedType:hookedType];
    
    return YES;
}

+ (BOOL)unhookClassMethodForClass:(__unsafe_unretained Class)targetClass
                   originalMethod:(SEL)originalMethod
                        newMethod:(SEL)newMethod
{
    XLClassHookedInfo *info = [targetClass xlClassHookedInfo];
    XLClassHookedInfoItem *item = [info itemForOrginalSelector:originalMethod];
    if (![item isSelectorHooked:newMethod]) {
        return NO;
    }
    
    SEL preSelector = [item preSelectorOfSelector:newMethod];
    if (!preSelector) {
        return NO;
    }
    
    Method mPreMethod = class_getClassMethod(targetClass, preSelector);
    if (!mPreMethod) {
        return NO;
    }
    Method mNewMethod = class_getClassMethod(targetClass, newMethod);
    if (!mNewMethod) {
        return NO;
    }
    
    IMP impPre = method_getImplementation(mPreMethod);
    IMP impNew = method_getImplementation(mNewMethod);
    method_setImplementation(mNewMethod, impPre);
    method_setImplementation(mPreMethod, impNew);
    
    [item unhookWithSelector:newMethod];
    
    return YES;
}

- (BOOL)isNSNull
{
    return [self isEqual:[NSNull null]];
}

+ (BOOL)containsInstanceMethod:(SEL)selector
{
    Method method = class_getInstanceMethod([self class], selector);
    Method supMethod = class_getInstanceMethod([self superclass], selector);
    if (method != NULL && method != supMethod)
    {
        return YES;
    }
    return NO;
}
- (BOOL)containsInstanceMethod:(SEL)selector
{
    return [[self class] containsInstanceMethod:selector];
}

+ (BOOL)containsClassMethod:(SEL)selector
{
    Method method = class_getClassMethod([self class], selector);
    Method supMethod = class_getClassMethod([self superclass], selector);
    if (method != NULL && method != supMethod)
    {
        return YES;
    }
    return NO;
}
- (BOOL)containsClassMethod:(SEL)selector
{
    return [[self class] containsClassMethod:selector];
}

- (BOOL)respondsToSelector:(SEL)selector excludingRootClass:(Class)rootClass
{
    Class currentClass = [self class];
    while (currentClass && currentClass != rootClass) {
        if ([currentClass containsInstanceMethod:selector]) {
            return YES;
        }
        currentClass = [currentClass superclass];
    }
    return NO;
}

- (NSString *)objectAddressString
{
    return [NSString stringWithFormat:@"%@", [NSValue valueWithNonretainedObject:self]];
}

- (void)setAssociatedObject:(id)object withKey:(NSString *)key
{
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             object,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)setAssociatedObject:(id)object withKey:(NSString *)key policyArray:(NSArray *)array
{
    objc_AssociationPolicy policy = OBJC_ASSOCIATION_ASSIGN;
    
    if ([array containsObject:@"nonatomic"]) {
        if ([array containsObject:@"copy"]) {
            policy = OBJC_ASSOCIATION_COPY_NONATOMIC;
        }
        else if (![array containsObject:@"weak"] && ![array containsObject:@"assign"]) {
            policy = OBJC_ASSOCIATION_RETAIN_NONATOMIC;
        }
    }
    else {
        if ([array containsObject:@"copy"]) {
            policy = OBJC_ASSOCIATION_COPY;
        }
        else if (![array containsObject:@"weak"] && ![array containsObject:@"assign"]) {
            policy = OBJC_ASSOCIATION_RETAIN;
        }
    }
    
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             object,
                             policy);
    
    if ([array containsObject:@"weak"] && object) {
        [NSObject listenToRecycledEventOfObject:object
                                recycledHandler:^{
                                    objc_setAssociatedObject(self,
                                                             key.UTF8String,
                                                             nil,
                                                             policy);
                                }];
    }
}
- (void)removeAssociatedObjectWithKey:(NSString *)key
{
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (id)associatedObjectWithKey:(NSString *)key
{
    return objc_getAssociatedObject(self, key.UTF8String);
}
+ (void)setAssociatedObject:(id)object withKey:(NSString *)key
{
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             object,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
+ (void)setAssociatedObject:(id)object withKey:(NSString *)key policyArray:(NSArray *)array
{
    objc_AssociationPolicy policy = OBJC_ASSOCIATION_ASSIGN;
    
    if ([array containsObject:@"nonatomic"]) {
        if ([array containsObject:@"copy"]) {
            policy = OBJC_ASSOCIATION_COPY_NONATOMIC;
        }
        else if (![array containsObject:@"weak"] && ![array containsObject:@"assign"]) {
            policy = OBJC_ASSOCIATION_RETAIN_NONATOMIC;
        }
    }
    else {
        if ([array containsObject:@"copy"]) {
            policy = OBJC_ASSOCIATION_COPY;
        }
        else if (![array containsObject:@"weak"] && ![array containsObject:@"assign"]) {
            policy = OBJC_ASSOCIATION_RETAIN;
        }
    }
    
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             object,
                             policy);
    
    if ([array containsObject:@"weak"] && object) {
        [NSObject listenToRecycledEventOfObject:object
                                recycledHandler:^{
                                    objc_setAssociatedObject(self,
                                                             key.UTF8String,
                                                             nil,
                                                             policy);
                                }];
    }
}
+ (void)removeAssociatedObjectWithKey:(NSString *)key
{
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
+ (id)associatedObjectWithKey:(NSString *)key
{
    return objc_getAssociatedObject(self, key.UTF8String);
}

- (void)setAssociatedObject:(id)object
{
    NSString *key = [object objectAddressString];
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             object,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)removeAssociatedObject:(id)object
{
    NSString *key = [object objectAddressString];
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (BOOL)isAssociatedWithObject:(id)object
{
    NSString *key = [object objectAddressString];
    if (objc_getAssociatedObject(self, key.UTF8String)) {
        return YES;
    }
    return NO;
}
+ (void)setAssociatedObject:(id)object
{
    NSString *key = [object objectAddressString];
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             object,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
+ (void)removeAssociatedObject:(id)object
{
    NSString *key = [object objectAddressString];
    objc_setAssociatedObject(self,
                             key.UTF8String,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
+ (BOOL)isAssociatedWithObject:(id)object
{
    NSString *key = [object objectAddressString];
    if (objc_getAssociatedObject(self, key.UTF8String)) {
        return YES;
    }
    return NO;
}

- (void)printSelf
{
    NSLog(@"%@", self);
}
- (void)printSelfAddress
{
    NSLog(@"%@", [self objectAddressString]);
}

@end

#pragma mark - C Functions

BOOL NSObjectIsEqual(NSObject *obj, NSObject *otherObj)
{
    return (obj == otherObj || [obj isEqual:otherObj]);
}

BOOL ProtocolContainsMethod(Protocol *aProtocol, SEL aSelector)
{
    // Check that protocol includes method.
    
    BOOL (^includesSelectorWithOptions)(Protocol*, SEL, BOOL, BOOL) =
    ^BOOL(Protocol *pro, SEL sel, BOOL req, BOOL inst)
    {
        unsigned int protocolMethodCount = 0;
        BOOL isRequiredMethod = req;
        BOOL isInstanceMethod = inst;
        struct objc_method_description *protocolMethodList;
        BOOL includesSelector = NO;
        protocolMethodList = protocol_copyMethodDescriptionList(pro, isRequiredMethod, isInstanceMethod, &protocolMethodCount);
        for (NSUInteger m = 0; m < protocolMethodCount; m++)
        {
            struct objc_method_description aMethodDescription = protocolMethodList[m];
            SEL aMethodSelector = aMethodDescription.name;
            if (aMethodSelector == sel)
            {
                includesSelector = YES;
                break;
            }
        }
        free(protocolMethodList);
        return includesSelector;
    };
    
    // Check for required and non-required methods of class and instance methods.
    
    if (includesSelectorWithOptions(aProtocol, aSelector, YES, YES)) {
        return YES;
    }
    if (includesSelectorWithOptions(aProtocol, aSelector, YES, NO)) {
        return YES;
    }
    if (includesSelectorWithOptions(aProtocol, aSelector, NO, NO)) {
        return YES;
    }
    if (includesSelectorWithOptions(aProtocol, aSelector, NO, YES)) {
        return YES;
    }
    return NO;
}
