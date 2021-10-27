#import "Imports.h"
#import "THelperClass.h"

@interface MBFingerTipView : UIImageView

@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) BOOL shouldAutomaticallyRemoveAfterTimeout;
@property (nonatomic, assign, getter=isFadingOut) BOOL fadingOut;

@end

@implementation MBFingerTipView
@end
@interface MBFingerTipOverlayWindow : UIWindow
@end
@implementation MBFingerTipOverlayWindow

// UIKit tries to get the rootViewController from the overlay window. Use the Fingertips window instead. This fixes
// issues with status bar behavior, as otherwise the overlay window would control the status bar.
// This logic can't work in this injected style implementation because we are actually UIWindow being augmented.

- (UIViewController *)rootViewController {
    return [super rootViewController];
}
@end
/*
@interface UIWindow (ours)
@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) BOOL fingerTipRemovalScheduled;
- (UIImage *)_generateTouchImage;
- (UIColor *)strokeColor;
- (UIColor *)fillColor;
- (CGFloat)touchAlpha;
- (NSTimeInterval)fadeDuration;
- (UIImage *)touchImage;
- (BOOL)active;
- (void)screenConnect:(NSNotification *)notification;
- (void)MBFingerTipWindow_commonInit;
- (BOOL)anyScreenIsMirrored;
- (void)updateFingertipsAreActive;
- (void)scheduleFingerTipRemoval;
- (void)cancelScheduledFingerTipRemoval;
- (void)removeInactiveFingerTips;
- (void)removeFingerTipWithHash:(NSUInteger)hash animated:(BOOL)animated;
- (BOOL)shouldAutomaticallyRemoveFingerTipForTouch:(UITouch *)touch;
@end
*/
%hook UIWindow

#import <objc/runtime.h>

%new - (UIImage *)_generateTouchImage {
    UIImage *_touchImage = nil;
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 50.0, 50.0)];
    
    UIGraphicsBeginImageContextWithOptions(clipPath.bounds.size, NO, 0);
    
    UIBezierPath *drawPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(25.0, 25.0)
                                                            radius:22.0
                                                        startAngle:0
                                                          endAngle:2 * M_PI
                                                         clockwise:YES];
    
    drawPath.lineWidth = 2.0;
    
    [self.strokeColor setStroke];
    [self.fillColor setFill];
    
    [drawPath stroke];
    [drawPath fill];
    
    [clipPath addClip];
    
    _touchImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return _touchImage;
}

%new - (void)setActive:(BOOL)active {
	objc_setAssociatedObject(self, @selector(active), [NSNumber numberWithBool:active], OBJC_ASSOCIATION_RETAIN);
}

//for now its always active when loaded, fix this later
%new - (BOOL)active {
	 return [objc_getAssociatedObject(self, @selector(active)) boolValue];
}


- (void)sendEvent:(UIEvent *)event {
   if (self.active) {
        if (!self.overlayWindow) {
        	[self MBFingerTipWindow_commonInit];
	}
        NSSet *allTouches = [event allTouches];
        for (UITouch *touch in [allTouches allObjects]) {
            
            switch (touch.phase) {
                case UITouchPhaseBegan:
                case UITouchPhaseMoved:
                case UITouchPhaseStationary: {
                    MBFingerTipView *touchView = (MBFingerTipView *)[self.overlayWindow viewWithTag:touch.hash];
                    if (touch.phase != UITouchPhaseStationary && touchView != nil && [touchView isFadingOut]) {
                        [touchView removeFromSuperview];
                        touchView = nil;
                    }
                    
                    if (touchView == nil && touch.phase != UITouchPhaseStationary) {
                        touchView = [[MBFingerTipView alloc] initWithImage:self.touchImage];
                        [self.overlayWindow addSubview:touchView];
                    }
                    
                    if ( ! [touchView isFadingOut]) {
                        touchView.alpha = self.touchAlpha;
                        touchView.center = [touch locationInView:self.overlayWindow];
                        touchView.tag = touch.hash;
                        touchView.timestamp = touch.timestamp;
                        touchView.shouldAutomaticallyRemoveAfterTimeout = [self shouldAutomaticallyRemoveFingerTipForTouch:touch];
                    }
                    break;
                }
                    
                case UITouchPhaseEnded:
                case UITouchPhaseCancelled: {
                    [self removeFingerTipWithHash:touch.hash animated:YES];
                    break;
                }
                default:
                    //HBLogDebug(@"#### [DEBUG] uncaught touch phase: %lu", touch.phase);
                    break;
            }
        }
    }
    %orig; //how super is called if u don't know
    //[super sendEvent:event];
    
    [self scheduleFingerTipRemoval]; // We may not see all UITouchPhaseEnded/UITouchPhaseCancelled events.
}
%new - (UIImage *)touchImage {
    UIImage *ti = objc_getAssociatedObject(self, @selector(touchImage));
    if (ti) return ti;
    ti = [self _generateTouchImage];
    objc_setAssociatedObject(self, @selector(touchImage),ti, OBJC_ASSOCIATION_RETAIN);
    return ti;
}

%new - (BOOL)fingerTipRemovalScheduled {
    return [objc_getAssociatedObject(self, @selector(fingerTipRemovalSceduled)) boolValue];
}

%new - (void)setFingerTipRemovalScheduled:(BOOL)fingerTipRemovalScheduled {
    objc_setAssociatedObject(self, @selector(fingerTipRemovalScheduled), [NSNumber numberWithBool:fingerTipRemovalScheduled], OBJC_ASSOCIATION_RETAIN);
}

%new - (UIWindow *)overlayWindow {
    return objc_getAssociatedObject(self, @selector(overlayWindow));
}

%new - (void)setOverlayWindow:(UIWindow *)overlayWindow {
    objc_setAssociatedObject(self, @selector(overlayWindow), overlayWindow, OBJC_ASSOCIATION_RETAIN);
}

%new - (void)screenConnect:(NSNotification *)notification
{
    [self updateFingertipsAreActive];
}

%new - (void)screenDisconnect:(NSNotification *)notification
{
    [self updateFingertipsAreActive];
}

%new - (BOOL)anyScreenIsMirrored
{
    if ( ! [UIScreen instancesRespondToSelector:@selector(mirroredScreen)])
        return NO;
    
    for (UIScreen *screen in [UIScreen screens])
    {
        if ([screen mirroredScreen] != nil)
            return YES;
    }
    
    return NO;
}

//these values could be set in the original version, for now they are read only

%new - (UIColor *)strokeColor {
    return [UIColor blackColor];
}

%new - (UIColor *)fillColor {
    return [UIColor whiteColor];
}

%new - (CGFloat)fadeDuration {
    return 0.3;
}

%new - (CGFloat)touchAlpha {
    return 0.5;
}

%new - (void)MBFingerTipWindow_commonInit {
    //self.strokeColor = [UIColor blackColor];
    //self.fillColor = [UIColor whiteColor];
    MBFingerTipOverlayWindow *overlayWindow = [[MBFingerTipOverlayWindow alloc] initWithFrame:self.frame];
    overlayWindow.userInteractionEnabled = NO;
    overlayWindow.windowLevel = UIWindowLevelStatusBar;
    overlayWindow.backgroundColor = [UIColor clearColor];
    overlayWindow.hidden = NO;
    UIViewController *rvc = [UIViewController new];
    rvc.view.backgroundColor = nil;
    rvc.view.userInteractionEnabled = false;
    overlayWindow.rootViewController = rvc;
    //self.touchAlpha   = 0.5;
    //self.fadeDuration = 0.3;
    self.overlayWindow = overlayWindow;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenConnect:)
                                                 name:UIScreenDidConnectNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenDisconnect:)
                                                 name:UIScreenDidDisconnectNotification
                                               object:nil];
    
    // Set up active now, in case the screen was present before the window was created (or application launched).
    //
    [self updateFingertipsAreActive];
    // iOS 13+ without this code the window never appears to actually be visible.
    if (@available(iOS 13, tvOS 13, *)) {
        // Only look for a new scene if we don't have one
        if (!self.overlayWindow.windowScene) {
            self.overlayWindow.windowScene = self.windowScene;
        }
    }
}

%new - (void)updateFingertipsAreActive {
    //No-Op
}


- (void)doesNotRecognizeSelector:(SEL)aSelector {
    %log;
    HBLogDebug(@"#### [DEBUG] does not recognizeSelector: %@", NSStringFromSelector(aSelector));
    %orig;
}

%new - (void)scheduleFingerTipRemoval {
    if (self.fingerTipRemovalScheduled)
        return;
    
    self.fingerTipRemovalScheduled = YES;
    [self performSelector:@selector(removeInactiveFingerTips) withObject:nil afterDelay:0.1];
}

%new - (void)cancelScheduledFingerTipRemoval {
    self.fingerTipRemovalScheduled = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeInactiveFingerTips) object:nil];
}

%new - (void)removeInactiveFingerTips {
    self.fingerTipRemovalScheduled = NO;
    
    NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];
    const CGFloat REMOVAL_DELAY = 0.2;
    
    for (MBFingerTipView *touchView in [self.overlayWindow subviews]) {
        if ( ! [touchView isKindOfClass:[MBFingerTipView class]])
            continue;
        
        if (touchView.shouldAutomaticallyRemoveAfterTimeout && now > touchView.timestamp + REMOVAL_DELAY)
            [self removeFingerTipWithHash:touchView.tag animated:YES];
    }
    
    if ([[self.overlayWindow subviews] count] > 0)
        [self scheduleFingerTipRemoval];
}

%new - (void)removeFingerTipWithHash:(NSUInteger)hash animated:(BOOL)animated {
    MBFingerTipView *touchView = (MBFingerTipView *)[self.overlayWindow viewWithTag:hash];
    if ( ! [touchView isKindOfClass:[MBFingerTipView class]])
        return;
    
    if ([touchView isFadingOut])
        return;
    
    BOOL animationsWereEnabled = [UIView areAnimationsEnabled];
    
    if (animated) {
        [UIView setAnimationsEnabled:YES];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:self.fadeDuration];
    }
    
    touchView.frame = CGRectMake(touchView.center.x - touchView.frame.size.width,
                                 touchView.center.y - touchView.frame.size.height,
                                 touchView.frame.size.width  * 2,
                                 touchView.frame.size.height * 2);
    
    touchView.alpha = 0.0;
    
    if (animated) {
        [UIView commitAnimations];
        [UIView setAnimationsEnabled:animationsWereEnabled];
    }
    
    touchView.fadingOut = YES;
    [touchView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:self.fadeDuration];
}

%new - (BOOL)shouldAutomaticallyRemoveFingerTipForTouch:(UITouch *)touch {
    // We don't reliably get UITouchPhaseEnded or UITouchPhaseCancelled
    // events via -sendEvent: for certain touch events. Known cases
    // include swipe-to-delete on a table view row, and tap-to-cancel
    // swipe to delete. We automatically remove their associated
    // fingertips after a suitable timeout.
    //
    // It would be much nicer if we could remove all touch events after
    // a suitable time out, but then we'll prematurely remove touch and
    // hold events that are picked up by gesture recognizers (since we
    // don't use UITouchPhaseStationary touches for those. *sigh*). So we
    // end up with this more complicated setup.
    
    UIView *view = [touch view];
    view = [view hitTest:[touch locationInView:view] withEvent:nil];
    
    while (view != nil) {
        if ([view isKindOfClass:[UITableViewCell class]]) {
            for (UIGestureRecognizer *recognizer in [touch gestureRecognizers]) {
                if ([recognizer isKindOfClass:[UISwipeGestureRecognizer class]])
                    return YES;
            }
        }
        
        if ([view isKindOfClass:[UITableView class]]) {
            if ([[touch gestureRecognizers] count] == 0)
                return YES;
        }
        
        view = view.superview;
    }
    
    return NO;
}
%end

%ctor {
    
    NSString *processName = [[[[NSProcessInfo processInfo] arguments] lastObject] lastPathComponent];
    HBLogDebug(@"Process name: %@", processName);
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleID = [bundle bundleIdentifier];
    NSDictionary *infoDict = [bundle infoDictionary];
    NSString *name = infoDict[@"CFBundleDisplayName"];
    if (!name){
        NSDictionary *localizedInfoDict = [bundle localizedInfoDictionary];
        if (localizedInfoDict){
            name = localizedInfoDict[@"CFBundleName"];
        } else {
            name = infoDict[@"CFBundleName"];
        }
    }
    NSDictionary *ourDict = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.nito.touchy.plist"];
    if ([bundleID isEqualToString:@"com.apple.springboard"]){
    	HBLogDebug(@"[touchy we got SpringBoard, listen for notifications!");
	[[THelperClass sharedInstance] listenForNotifications];
    }
    NSNumber *value = [ourDict objectForKey:bundleID];
    NSNumber *valueName = [ourDict objectForKey:name];
    HBLogDebug(@"[touchy] bundle ID %@ bundle display name: %@", bundleID, name);
    if ([value boolValue] == YES || [valueName boolValue] == YES) {
        HBLogDebug(@"[touchy] initialize our code!");
	id app = [UIApplication sharedApplication];
	id window = [app keyWindow];
	if (!app){
		THelperClass *helper = [THelperClass sharedInstance];
		[helper delayedInjection];
	}
	/*
	HBLogDebug(@"[touchy] app: %@ keyWindow: %@", app, window);
	    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        	HBLogDebug(@"[touchy] logger dispatched after 1 second");    
		id app = [UIApplication sharedApplication];
		UIWindow *window = [app keyWindow];
		HBLogDebug(@"[touchy] app: %@ keyWindow: %@", app, window);
		[window MBFingerTipWindow_commonInit];
		[window setActive:true];
        });
 */
    }
}
