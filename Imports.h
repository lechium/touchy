
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

