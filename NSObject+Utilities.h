/*
 Erica Sadun, http://ericasadun.com
 iPhone Developer's Cookbook, 3.0 Edition
 BSD License, Use at your own risk
 */

#import <Foundation/Foundation.h>

typedef void(^BasicBlockType)();


@interface NSObject (TC_Utilities)

+ (void)tc_swizzle:(SEL)aSelector;

// Return all superclasses of object
+ (NSArray *) superclasses;
- (NSArray *) superclasses;

// Examine
+ (NSString *) dump;
- (NSString *) dump;

// Selector Utilities
- (NSInvocation *) invocationWithSelectorAndArguments: (SEL) selector,...;
- (BOOL) performSelector: (SEL) selector withReturnValueAndArguments: (void *) result, ...;
- (const char *) returnTypeForSelector:(SEL)selector;

// Request return value from performing selector
- (id) objectByPerformingSelectorWithArguments: (SEL) selector, ...;
- (__autoreleasing id) objectByPerformingSelector:(SEL)selector withObject:(id) object1 andObject: (id) object2;
- (id) objectByPerformingSelector:(SEL)selector withObject:(id) object1;
- (id) objectByPerformingSelector:(SEL)selector;

// Delay Utilities
void _PerformBlockAfterDelay(BasicBlockType block, NSTimeInterval delay);
- (void) performSelector: (SEL) selector withCPointer: (void *) cPointer afterDelay: (NSTimeInterval) delay;
- (void) performSelector: (SEL) selector withInt: (int) intValue afterDelay: (NSTimeInterval) delay;
- (void) performSelector: (SEL) selector withFloat: (float) floatValue afterDelay: (NSTimeInterval) delay;
- (void) performSelector: (SEL) selector withBool: (BOOL) boolValue afterDelay: (NSTimeInterval) delay;
- (void) performSelector: (SEL) selector afterDelay: (NSTimeInterval) delay;
- (void) performSelector: (SEL) selector withDelayAndArguments: (NSTimeInterval) delay,...;

// Return Values, allowing non-object returns
- (NSValue *) valueByPerformingSelector:(SEL)selector withObject:(id) object1 withObject: (id) object2;
- (NSValue *) valueByPerformingSelector:(SEL)selector withObject:(id) object1;
- (NSValue *) valueByPerformingSelector:(SEL)selector;

// Access to object essentials for run-time checks. Stored by class in dictionary.
@property (readonly) NSDictionary *selectors;
@property (readonly) NSDictionary *properties;
@property (readonly) NSDictionary *ivars;
@property (readonly) NSDictionary *protocols;

+ (NSArray *) getPropertyListForClass;

// Check for properties, ivar. Use respondsToSelector: and conformsToProtocol: as well
- (BOOL) hasProperty: (NSString *) propertyName;
- (BOOL) hasIvar: (NSString *) ivarName;
+ (BOOL) classExists: (NSString *) className;
+ (id) instanceOfClassNamed: (NSString *) className;

// Attempt selector if possible
- (id) safePerformSelector: (SEL) aSelector withObject: (id) object1 withObject: (id) object2;
- (id) safePerformSelector: (SEL) aSelector withObject: (id) object1;
- (id) safePerformSelector: (SEL) aSelector;

// Choose the first selector that the object responds to
- (SEL) chooseSelector: (SEL) aSelector, ...;
@end