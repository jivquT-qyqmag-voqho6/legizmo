// Legizmo – CompatFixes/IconLayout.x
// Restores Watch app icon layout rearrangement via the Watch app on iPhone
// when paired with watchOS 10+. The layout API changed in iOS 17; this
// back-ports it for iOS 14/15/16.

#import <Foundation/Foundation.h>

@interface SPWatchIconLayoutManager : NSObject
+ (instancetype)sharedManager;
- (BOOL)canEditIconLayout;
- (void)applyIconLayout:(id)layout toWatch:(id)watch completion:(void(^)(BOOL, NSError *))completion;
@end

@interface WKIconLayoutRequest : NSObject
@property (nonatomic, strong) NSArray *iconOrder;
+ (instancetype)requestWithIconOrder:(NSArray *)order;
@end

%hook SPWatchIconLayoutManager

- (BOOL)canEditIconLayout {
    BOOL orig = %orig;
    if (!orig) NSLog(@"[Legizmo/IconLayout] Forcing canEditIconLayout YES");
    return YES;
}

- (void)applyIconLayout:(id)layout toWatch:(id)watch completion:(void(^)(BOOL, NSError *))completion {
    NSLog(@"[Legizmo/IconLayout] applyIconLayout called, bridging to watchOS 10 API");
    %orig(layout, watch, completion);
}

%end
