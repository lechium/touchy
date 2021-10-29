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
            if (![window overlayWindow]){
                [window MBFingerTipWindow_commonInit];
            }
        }
		[window setActive:activate];
	}
}

- (void)settingsChanged:(NSDictionary *)userInfo {
	id app = [UIApplication sharedApplication];
	UIWindow *window = [app keyWindow];
	if ([window active]) {
        HBLogDebug(@"[touchy] touches are currently active, deactivate!");
		[self toggleAllWindows:false];
	} else {
        HBLogDebug(@"[touchy] touches are currently inactive, activate!");
		[self toggleAllWindows:true];
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

- (void)listenForNotifications {
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge const void *)(self), SettingsChangedNotificationFired, CFSTR("com.nito.touchy.springboardchanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)inject:(id)sender {
	HBLogDebug(@"inject was called!");
	id app = [UIApplication sharedApplication];
	UIWindow *window = [app keyWindow];
    HBLogDebug(@"window: %@", window);
	if ([window overlayWindow]){
		return;
	}
	[window MBFingerTipWindow_commonInit];
	[window setActive:true];
	
}

- (void)delayedInjection {
	HBLogDebug(@"[touchy] delayedInjection");
    //UIApplicationWillEnterForegroundNotification
    //UIWindowDidBecomeKeyNotification
	[[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(inject:) name:UIWindowDidBecomeKeyNotification object:nil];
    return;
	NSString *processName = [[[[NSProcessInfo processInfo] arguments] lastObject] lastPathComponent];
	if (![processName isEqualToString:@"SpringBoard"]){
		return;
	}
	HBLogDebug(@"[touchy] WE ARE SPRINGBOARD");
	if (self.injectionTimer){
		[self.injectionTimer invalidate];
		self.injectionTimer = nil;
	}
	self.injectionTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:true block:^(NSTimer * _Nonnull timer) {
		id app = [UIApplication sharedApplication];
		UIWindow *window = [app keyWindow];
		if (!window){
			[self delayedInjection];
			return;
		}
		if ([window overlayWindow]){
			return;
		}
		[window MBFingerTipWindow_commonInit];
		[window setActive:true];
		//[self.injectionTimer invalidate];
		//self.injectionTimer = nil;
    }];
}
@end
