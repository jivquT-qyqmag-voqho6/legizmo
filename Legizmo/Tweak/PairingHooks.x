// Legizmo – PairingHooks.x
// Deep hooks into mediaremoted and the Watch pairing flow.
// Handles both "Tweak Method" (jailbroken) and "Native Method" (persisted).

#import <Foundation/Foundation.h>
#import <substrate.h>

// ── Private headers (reverse-engineered) ─────────────────────────────────────

@interface MRPairingSession : NSObject
@property (nonatomic, strong) NSString *watchOSVersion;
@property (nonatomic, strong) NSString *watchSerialNumber;
@property (nonatomic, assign) NSInteger pairingMethod; // 0=tweak, 1=native
- (BOOL)beginPairingWithCompletion:(void(^)(BOOL success, NSError *error))completion;
- (void)setSpoofedHostVersion:(NSString *)version;
@end

@interface MRPairingValidator : NSObject
+ (instancetype)sharedInstance;
- (BOOL)isWatchOSVersion:(NSString *)watchOS compatibleWithIOSVersion:(NSString *)ios;
- (NSString *)currentHostVersion;
@end

@interface MRWatchInfoManager : NSObject
+ (instancetype)sharedInstance;
- (NSDictionary *)watchInfoFromQRPayload:(NSData *)payload;
- (NSString *)watchOSVersionFromInfo:(NSDictionary *)info;
@end

// ── Version spoof table ───────────────────────────────────────────────────────
// Maps real watchOS major to the iOS version string we present during handshake.
// Apple's compatibility check is: iOS_major >= watchOS_major - 1
static NSDictionary<NSString *, NSString *> *versionSpoofTable(void) {
    return @{
        @"11": @"17.0",  // watchOS 11 → present as iOS 17
        @"10": @"16.0",  // watchOS 10 → present as iOS 16
        @"9":  @"15.0",  // watchOS 9  → present as iOS 15
        @"8":  @"14.0",  // watchOS 8  → present as iOS 14
        @"7":  @"13.0",  // watchOS 7  → present as iOS 13
    };
}

// Extract major version number string from a version string like "11.2.1"
static NSString *majorVersion(NSString *v) {
    return [[v componentsSeparatedByString:@"."] firstObject] ?: @"0";
}

// ── MRPairingValidator hooks ──────────────────────────────────────────────────
%hook MRPairingValidator

- (BOOL)isWatchOSVersion:(NSString *)watchOS compatibleWithIOSVersion:(NSString *)ios {
    NSString *major = majorVersion(watchOS);
    NSString *spoof = versionSpoofTable()[major];
    if (spoof) {
        NSLog(@"[Legizmo/Pairing] Spoofing iOS version: real=%@ spoof=%@ for watchOS=%@", ios, spoof, watchOS);
        return %orig(watchOS, spoof);
    }
    return %orig;
}

- (NSString *)currentHostVersion {
    // Return a sufficiently high version so Apple's check always passes.
    // The real iOS version is used for everything else.
    NSString *real = %orig;
    NSLog(@"[Legizmo/Pairing] currentHostVersion queried, real=%@", real);
    return real; // MRPairingSession overrides per-session via setSpoofedHostVersion
}

%end


// ── MRPairingSession hooks ────────────────────────────────────────────────────
%hook MRPairingSession

- (BOOL)beginPairingWithCompletion:(void(^)(BOOL success, NSError *error))completion {
    NSString *watchOS = self.watchOSVersion;
    NSString *major   = majorVersion(watchOS ?: @"0");
    NSString *spoof   = versionSpoofTable()[major];

    if (spoof) {
        NSLog(@"[Legizmo/Pairing] Session: setting spoofed host version %@ for watchOS %@", spoof, watchOS);
        [self setSpoofedHostVersion:spoof];
    }

    return %orig(completion);
}

%end


// ── MRWatchInfoManager hooks (QR scanner) ─────────────────────────────────────
%hook MRWatchInfoManager

- (NSDictionary *)watchInfoFromQRPayload:(NSData *)payload {
    NSDictionary *info = %orig;
    if (!info) return info;

    NSString *watchOS = [self watchOSVersionFromInfo:info];
    NSString *major   = majorVersion(watchOS ?: @"0");
    BOOL supported    = versionSpoofTable()[major] != nil;

    NSLog(@"[Legizmo/Scanner] Scanned Watch — watchOS: %@, Legizmo supported: %@",
          watchOS, supported ? @"YES" : @"NO");

    // Inject Legizmo support metadata into the info dict for the UI
    NSMutableDictionary *enriched = [info mutableCopy];
    enriched[@"LGZWatchOSVersion"] = watchOS ?: @"Unknown";
    enriched[@"LGZSupported"]      = @(supported);
    return [enriched copy];
}

%end
