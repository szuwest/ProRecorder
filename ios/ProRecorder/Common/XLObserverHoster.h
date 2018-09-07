//
//  XLObserverHoster.h
//  XL
//
//

#import <Foundation/Foundation.h>

@protocol XLObserverHosterProto <NSObject>
@optional

@property (nonatomic, readonly) NSArray *observers;

- (void)addObserver:(id)observer;

- (void)removeObserver:(id)observer;

- (void)removeAllObservers;

- (void)notifyObservers:(SEL)selector;

- (void)notifyObservers:(SEL)selector withObject:(id)param;

- (void)notifyObservers:(SEL)selector withObjects:firstObj,...;

@end

@interface XLObserverHoster : NSObject <XLObserverHosterProto>

@end
