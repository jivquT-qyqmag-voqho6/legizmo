// Legizmo – CompatFixes/ECG.x
// Bridges ECG (electrocardiogram) data from watchOS to the Health app
// on iOS versions that don't natively support it (< iOS 14.2 for some regions).
// The Health database schema is patched to accept the ECG record type.

#import <Foundation/Foundation.h>

@interface HKElectrocardiogram : NSObject
@property (nonatomic, assign) NSInteger classification; // HKElectrocardiogramClassification
@property (nonatomic, strong) NSDate   *startDate;
@property (nonatomic, strong) NSDate   *endDate;
@end

@interface HKHealthStore : NSObject
- (BOOL)_canSaveECGData;
- (void)_saveECGSample:(HKElectrocardiogram *)ecg withCompletion:(void(^)(BOOL, NSError*))completion;
@end

@interface HKDatabaseManager : NSObject
+ (instancetype)sharedManager;
- (BOOL)isECGTypeRegistered;
- (void)registerECGType;
@end

// ── Hooks ─────────────────────────────────────────────────────────────────────
%hook HKHealthStore

- (BOOL)_canSaveECGData {
    NSLog(@"[Legizmo/ECG] Forcing _canSaveECGData YES");
    return YES;
}

%end

%hook HKDatabaseManager

- (BOOL)isECGTypeRegistered {
    BOOL orig = %orig;
    if (!orig) {
        NSLog(@"[Legizmo/ECG] ECG type not registered — registering now");
        [self registerECGType];
    }
    return YES;
}

%end


%ctor {
    NSLog(@"[Legizmo/ECG] ECG compat fix loaded");
    %init;
}
