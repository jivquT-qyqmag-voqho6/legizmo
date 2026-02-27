// Legizmo – Tweak.x
// Entry point: initialises all hook groups and reads user preferences.
// Uses Logos (Theos) syntax: %hook, %orig, %group, %init, %ctor, %dtor

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// ── Preference keys ──────────────────────────────────────────────────────────
#define PREFS_PATH         @"/var/jb/var/mobile/Library/Preferences/com.lunotech11.legizmo.plist"
#define kEnabled           @"LGZEnabled"
#define kPairingMethod     @"LGZPairingMethod"   // @"tweak" | @"native"
#define kBlockIncompat     @"LGZBlockIncompatibleUpdates"
#define kCompatBloodOx     @"LGZCompatBloodOxygen"
#define kCompatECG         @"LGZCompatECG"
#define kCompatScreenshot  @"LGZCompatScreenshot"
#define kCompatIconLayout  @"LGZCompatIconLayout"

// ── Shared helpers ────────────────────────────────────────────────────────────

NSDictionary *LGZPrefs(void) {
    return [NSDictionary dictionaryWithContentsOfFile:PREFS_PATH] ?: @{};
}

BOOL LGZBoolPref(NSString *key, BOOL def) {
    NSDictionary *p = LGZPrefs();
    return p[key] ? [p[key] boolValue] : def;
}

// Current device iOS version as a float for quick comparisons
static float sIOSVersion = 0.f;
static float IOSVersion(void) {
    if (sIOSVersion == 0.f)
        sIOSVersion = [UIDevice currentDevice].systemVersion.floatValue;
    return sIOSVersion;
}

// ── SpringBoard group: Watch app version-gate patches ─────────────────────────
%group SpringBoard

// SPWatchAppController handles the UI in the Watch app on iPhone.
// -[SPWatchAppController _validatePairedWatchFirmware] returns NO when
// the paired watchOS is unsupported, preventing pairing UI from appearing.
%hook SPWatchAppController
- (BOOL)_validatePairedWatchFirmware {
    if (!LGZBoolPref(kEnabled, YES)) return %orig;
    // Always return YES — Legizmo handles compatibility itself
    return YES;
}

// Block OTA update banners for incompatible watchOS versions
- (BOOL)shouldShowUpdateBannerForWatchOSVersion:(NSString *)version {
    if (!LGZBoolPref(kBlockIncompat, YES)) return %orig;
    // TODO: compare version against LGZ supported max; block if beyond
    NSLog(@"[Legizmo] OTA update check intercepted for watchOS %@", version);
    return %orig;
}
%end

%end // group SpringBoard


// ── mediaremoted group: core pairing version check ────────────────────────────
%group Mediaremoted

// MRPairingManager performs the actual version-enforcement during BT pairing.
// The private method -_pairingAllowedForWatchOSVersion: is the gatekeeper.
%hook MRPairingManager
- (BOOL)_pairingAllowedForWatchOSVersion:(id)version {
    if (!LGZBoolPref(kEnabled, YES)) return %orig;
    NSLog(@"[Legizmo] Pairing check bypassed for watchOS version: %@", version);
    return YES;
}

// Protocol handshake version negotiation — return a version the Watch accepts
- (NSInteger)_negotiatedProtocolVersionWithWatch:(id)watch {
    if (!LGZBoolPref(kEnabled, YES)) return %orig;
    NSInteger orig = %orig;
    NSLog(@"[Legizmo] Protocol version negotiated: %ld", (long)orig);
    // Return orig; hooks in PairingHooks.x handle deeper protocol bridging
    return orig;
}
%end

%end // group Mediaremoted


// ── companionappd group: message format translation ───────────────────────────
%group Companionappd

// CAWatchCompanionManager encodes/decodes Bluetooth messages between devices.
// New watchOS versions change message schemas; we bridge old ↔ new here.
%hook CAWatchCompanionManager
- (NSData *)encodedMessageForPayload:(id)payload {
    if (!LGZBoolPref(kEnabled, YES)) return %orig;
    // SyncHooks.x contains the full translation table
    return %orig;
}

- (id)decodedPayloadFromMessage:(NSData *)message {
    if (!LGZBoolPref(kEnabled, YES)) return %orig;
    return %orig;
}
%end

%end // group Companionappd


// ── healthd group: health feature activation ──────────────────────────────────
%group Healthd

%hook HKHealthStore
// Blood Oxygen capability check
- (BOOL)supportsHealthRecords {
    if (!LGZBoolPref(kCompatBloodOx, YES)) return %orig;
    return YES;
}
%end

%end // group Healthd


// ── Constructor: init groups based on process ─────────────────────────────────
%ctor {
    NSString *proc = [NSProcessInfo processInfo].processName;
    NSLog(@"[Legizmo] Loaded into process: %@", proc);

    if ([proc isEqualToString:@"SpringBoard"]) {
        %init(SpringBoard);
    } else if ([proc isEqualToString:@"mediaremoted"]) {
        %init(Mediaremoted);
    } else if ([proc isEqualToString:@"companionappd"]) {
        %init(Companionappd);
    } else if ([proc isEqualToString:@"healthd"]) {
        %init(Healthd);
    }
}
