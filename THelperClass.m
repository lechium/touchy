#import "Imports.h"
#import "THelperClass.h"
#import <UIKit/UIKit.h>
@implementation THelperClass

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static THelperClass *shared;
    dispatch_once(&onceToken, ^{
        shared = [[THelperClass alloc] init];
    });
    return shared;
}

- (void)delayedInjection {
	//NSLog(@"[touchy] delayedInjection");
	if (self.injectionTimer){
		[self.injectionTimer invalidate];
		self.injectionTimer = nil;
	}
	self.injectionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:true block:^(NSTimer * _Nonnull timer) {
	 //	HBLogDebug(@"[touchy] logger dispatched after 1 second");    
		id app = [UIApplication sharedApplication];
		UIWindow *window = [app keyWindow];
		if (!window){
			[self delayedInjection];
			return;
		}
		if ([window overlayWindow]){
	//		HBLogDebug(@"window already exists, do nothing");
			return;
		}
	//	HBLogDebug(@"[touchy] app: %@ keyWindow: %@", app, window);
		[window MBFingerTipWindow_commonInit];
		[window setActive:true];
		//[self.injectionTimer invalidate];
		//self.injectionTimer = nil;
    }];
}
@end
