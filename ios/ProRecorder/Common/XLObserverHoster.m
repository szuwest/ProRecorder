//
//  XLObserverHoster.m
//  XL
//

#import "XLObserverHoster.h"
#import "NSObject+XL.h"

@interface XLObserverHoster ()
{
    NSMutableArray *_observers;
}
@end

@implementation XLObserverHoster

- (id)init {
    if (self = [super init]) {
        _observers = [[NSMutableArray alloc] initWithCapacity:3];
    }
    return self;
}

- (BOOL)isObserverExists:(id)observer
{
    for (NSValue *value in _observers) {
        if ([value nonretainedObjectValue] == observer) {
            return YES;
        }
    }
    return NO;
}

- (void)addObserver:(id)observer {
    if (![self isObserverExists:observer]) {
        NSValue *value = [NSValue valueWithNonretainedObject:observer];
        [_observers addObject:value];
        
        // 通过监听释放
        [NSObject listenToRecycledEventOfObject:observer
                                recycledHandler:^{
                                    [_observers removeObject:value];
                                }];
    }
}

- (void)removeObserver:(id)observer {
    for (NSValue *value in _observers) {
        if ([value nonretainedObjectValue] == observer) {
            [_observers removeObject:value];
            return ;
        }
    }
}

- (void)removeAllObservers {
    [_observers removeAllObjects];
}

- (void)notifyObservers:(SEL)selector {
    [self notifyObservers:selector withObject:self];
}

- (void)notifyObservers:(SEL)selector withObject:(id)param {
    NSArray *arObs = self.observers;
    for (id o in arObs) {
        if ([o respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [o performSelector:selector withObject:param];
#pragma clang diagnostic pop
        }
    }
}

- (void)notifyObservers:(SEL)selector withObjects:firstObj,...
{
    id eachObject;
    va_list argList;
    
    NSArray *arObs = self.observers;
    for (id o in arObs) {
        if ([o respondsToSelector:selector]) {
            
            NSMethodSignature *sig = [[o class] instanceMethodSignatureForSelector:selector];
            NSInvocation *invocation=[NSInvocation invocationWithMethodSignature:sig];
            [invocation setTarget:o];
            [invocation setSelector:selector];
            if (firstObj) {
                int index = 2;
                [invocation setArgument:(void*)&firstObj atIndex:(index++)];
                
                va_start(argList,firstObj);
                while ((eachObject = va_arg(argList, id))) {
                    [invocation setArgument:(void*)&eachObject atIndex:(index++)];
                }
                va_end(argList);
            }
            [invocation invoke];
        }
    }
}

- (NSArray *)observers {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:_observers.count];
    for (NSValue *value in _observers) {
        [array addObject:[value nonretainedObjectValue]];
    }
    return array;
}

@end
