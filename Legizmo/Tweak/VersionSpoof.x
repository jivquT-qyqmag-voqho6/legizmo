// Legizmo – VersionSpoof.x
// Hooks NSProcessInfo and UIDevice version accessors in targeted processes
// so that any internal iOS version check returns a spoofed value that
// satisfies Apple's pairing/feature requirements.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// We only activate spoofing inside mediaremoted and companionappd.
// SpringBoard and healthd use their own targeted hooks instead.

// The spoofed version is set once during %ctor based on the paired Watch's
// watchOS version, which is read from Legizmo's shared preferences file.

#define SPOOF_PREFS @"/var/jb/var/mobile/Library/Preferences/com.lunotech11.legizmo.plist"

static NSString *sSpoofedVersion = nil;

static NSString *spoofedVersionForWatchOS(NSString *watchOS) {
    // Must be >= watchOS major - 1 to satisfy Apple's check
    int major = (int)[[[watchOS componentsSeparatedByString:@"."] firstObject] integerValue];
    return [NSString stringWithFormat:@"%d.0", MAX(major, 14)];
}

static void loadSpoofedVersion(void) {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:SPOOF_PREFS];
    NSString *watchOS   = prefs[@"LGZPairedWatchOSVersion"];
    if (watchOS.length) {
        sSpoofedVersion = spoofedVersionForWatchOS(watchOS);
        NSLog(@"[Legizmo/Spoof] Loaded spoofed version %@ for watchOS %@", sSpoofedVersion, watchOS);
    }
}

// ── NSProcessInfo hooks ───────────────────────────────────────────────────────
%hook NSProcessInfo

- (NSOperatingSystemVersion)operatingSystemVersion {
    if (!sSpoofedVersion) return %orig;

    NSArray *parts = [sSpoofedVersion componentsSeparatedByString:@"."];
    NSOperatingSystemVersion v = {
        .majorVersion = parts.count > 0 ? [parts[0] integerValue] : 14,
        .minorVersion = parts.count > 1 ? [parts[1] integerValue] : 0,
        .patchVersion = parts.count > 2 ? [parts[2] integerValue] : 0,
    };
    return v;
}

- (BOOL)isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion)version {
    if (!sSpoofedVersion) return %orig;
    // If the real version satisfies the requirement, use that.
    if (%orig) return YES;
    // Otherwise check if our spoofed version satisfies it.
    NSOperatingSystemVersion spoof = [self operatingSystemVersion];
    if (spoof.majorVersion > version.majorVersion) return YES;
    if (spoof.majorVersion == version.majorVersion && spoof.minorVersion >= version.minorVersion) return YES;
    return NO;
}

%end


// ── UIDevice hooks ────────────────────────────────────────────────────────────
%hook UIDevice

- (NSString *)systemVersion {
    if (!sSpoofedVersion) return %orig;
    return sSpoofedVersion;
}

%end


// ── Constructor ───────────────────────────────────────────────────────────────
%ctor {
    NSString *proc = [NSProcessInfo processInfo].processName;
    // Only activate in daemons that perform version checks
    if ([proc isEqualToString:@"mediaremoted"] ||
        [proc isEqualToString:@"companionappd"]) {
        loadSpoofedVersion();
        if (sSpoofedVersion) {
            %init;
            NSLog(@"[Legizmo/Spoof] Version spoof active in %@: %@", proc, sSpoofedVersion);
        }
    }
}
