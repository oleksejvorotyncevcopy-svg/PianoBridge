ARCHS = armv7
TARGET = iphone:clang:latest:6.0
INSTALL_TARGET_PROCESSES = PianoBridge

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = PianoBridge

PianoBridge_FILES = main.m XXAppDelegate.m XXRootViewController.m
PianoBridge_FRAMEWORKS = UIKit Foundation ExternalAccessory CoreMIDI
PianoBridge_CFLAGS = -fobjc-arc
PianoBridge_CODESIGN_FLAGS = -Sentitlements.plist
include $(THEOS_MAKE_PATH)/application.mk

