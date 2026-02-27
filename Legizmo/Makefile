export THEOS ?= $(HOME)/theos
export THEOS_MAKE_PATH := $(THEOS)/makefiles

# ── Build config ──────────────────────────────────────────────────────────────
ARCHS           := arm64 arm64e
TARGET          := iphone:clang:16.5:14.0
PACKAGE_VERSION := 5.0.0

# Rootless by default; pass THEOS_PACKAGE_SCHEME=rootful for rootful
include $(THEOS)/makefiles/common.mk

# ── Tweak ─────────────────────────────────────────────────────────────────────
TWEAK_NAME      := Legizmo

Legizmo_FILES := \
	Tweak/Tweak.x \
	Tweak/PairingHooks.x \
	Tweak/SyncHooks.x \
	Tweak/VersionSpoof.x \
	Tweak/CompatFixes/BloodOxygen.x \
	Tweak/CompatFixes/ECG.x \
	Tweak/CompatFixes/Screenshot.x \
	Tweak/CompatFixes/IconLayout.x

Legizmo_CFLAGS  := -fobjc-arc -Wno-unused-variable
Legizmo_LDFLAGS := -framework Foundation -framework UIKit -framework WatchConnectivity

# Inject into relevant daemons and SpringBoard
Legizmo_INSTALL_PATH := /Library/MobileSubstrate/DynamicLibraries
Legizmo_FILTER       := { Bundles: [com.apple.springboard, com.apple.mediaremoted, com.apple.companionappd, com.apple.healthd] }

# ── Preferences bundle ────────────────────────────────────────────────────────
BUNDLE_NAME              := LegizmoPreferences
LegizmoPreferences_FILES := \
	Preferences/RootListController.m \
	Preferences/PairingController.m \
	Preferences/CompatController.m

LegizmoPreferences_INSTALL_PATH   := /Library/PreferenceBundles
LegizmoPreferences_CFLAGS         := -fobjc-arc
LegizmoPreferences_PRIVATE_FRAMEWORKS := Preferences

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk

# ── Hooks ─────────────────────────────────────────────────────────────────────
after-install::
	install.exec "killall -9 SpringBoard mediaremoted companionappd healthd || true"

clean::
	rm -rf packages/ .theos/
