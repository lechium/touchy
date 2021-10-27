#import "Imports.h"
#import "THelperClass.h"
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
@implementation THelperClass

static void SettingsChangedNotificationFired(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	[(__bridge THelperClass*)observer settingsChanged:(__bridge NSDictionary*)userInfo];
}

- (void)toggleAllWindows:(BOOL)activate {
	NSArray *windows = [[UIApplication sharedApplication] windows];
	for (UIWindow *window in windows) {
		if (activate){
			[window MBFingerTipWindow_commonInit];
		}
		[window setActive:activate];
	}
}

- (void)settingsChanged:(NSDictionary *)userInfo {
	NSLog(@"[touchy] settingsChanged: %@", userInfo);
	id app = [UIApplication sharedApplication];
	UIWindow *window = [app keyWindow];
	if ([window active]) {
		NSLog(@"[touchy] touches are currently active, deactivate!");
		//[window setActive:false];
		[self toggleAllWindows:false];
	} else {
		NSLog(@"[touchy] touches are currently inactive, activate!");
		[self toggleAllWindows:true];
		//[window MBFingerTipWindow_commonInit];
		//[window setActive:true];
	}
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static THelperClass *shared;
    dispatch_once(&onceToken, ^{
        shared = [[THelperClass alloc] init];
    });
    return shared;
}
//CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), &daemon_restarted_callback, daemon_restarted_callback, CFSTR("com.rpetrich.rocketd.started"), NULL, CFNotificationSuspensionBehaviorCoalesce);
- (void)listenForNotifications {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self), SettingsChangedNotificationFired, CFSTR("com.nito.touchy.springboardchanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
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
