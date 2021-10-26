#import <Foundation/Foundation.h>

@interface THelperClass: NSObject
@property NSTimer *injectionTimer;
+ (instancetype)sharedInstance;
- (void)delayedInjection;
@end
