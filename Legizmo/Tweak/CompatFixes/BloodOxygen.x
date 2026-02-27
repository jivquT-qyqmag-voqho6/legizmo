// Legizmo – CompatFixes/BloodOxygen.x
// Enables Blood Oxygen (SpO2) data pipeline on iOS versions < 14
// by patching HKHealthStore capability checks and activating the
// peripheral Bluetooth service expected by watchOS.

#import <Foundation/Foundation.h>

// ── Private HealthKit interfaces ──────────────────────────────────────────────
@interface HKHealthStore : NSObject
+ (instancetype)new;
- (BOOL)supportsHealthRecords;
- (void)_activateBloodOxygenMonitoring;
- (NSSet *)_availableHealthTypes;
@end

@interface HKBloodOxygenSaturationTypeIdentifier : NSObject
@end

@interface HKObjectType : NSObject
+ (id)quantityTypeForIdentifier:(NSString *)identifier;
@end

// ── Hooks ─────────────────────────────────────────────────────────────────────
%hook HKHealthStore

- (BOOL)supportsHealthRecords {
    // iOS 12/13 returns NO; we force YES to unlock Blood Oxygen pipeline
    BOOL orig = %orig;
    if (!orig) {
        NSLog(@"[Legizmo/BloodOxygen] Forcing supportsHealthRecords YES");
    }
    return YES;
}

// Activate Blood Oxygen Bluetooth peripheral UUID registration
+ (void)load {
    NSLog(@"[Legizmo/BloodOxygen] HKHealthStore loaded — scheduling SpO2 activation");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        HKHealthStore *store = [HKHealthStore new];
        if ([store respondsToSelector:@selector(_activateBloodOxygenMonitoring)]) {
            [store _activateBloodOxygenMonitoring];
            NSLog(@"[Legizmo/BloodOxygen] SpO2 monitoring activated");
        }
    });
}

%end
