# touchy
Leverage https://github.com/mapbox/Fingertips (showing touches in targeted application) on jailbroken devices through an applist bundle

It it possible to get it to show touches on SpringBoard as well, but currently it must be toggled through plutil and triggered manually through cycript until I improve the tweak.

```
plutil -value 1 -type bool -key com.apple.springboard /var/mobile/Library/Preferences/com.nito.touchy.plist

killall -9 SpringBoard
cycript -p SpringBoard
 w = [UIApp keyWindow]
 [w MBFingerTipWindow_commonInit]
 [w setActive:true]
```

Conversely, to turn touches off in SpringBoard the following would be necessary

```
plutil -remove -key com.apple.springboard /var/mobile/Library/Preferences/com.nito.touchy.plist

killall -9 SpringBoard
```
