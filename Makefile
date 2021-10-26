export GO_EASY_ON_ME=1
export DEBUG=1
THEOS_DEVICE_IP=xphone
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = touchy 

touchy_FILES = Tweak.x THelperClass.m
touchy_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
