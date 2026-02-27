// Legizmo – CompatFixes/Screenshot.x
// Restores the ability to take screenshots on Apple Watch and have them
// appear in the iPhone's Photos app when running unsupported iOS/watchOS combos.

#import <Foundation/Foundation.h>

@interface WCSession : NSObject
+ (instancetype)defaultSession;
- (void)_processScreenshotData:(NSData *)data metadata:(NSDictionary *)metadata;
@end

@interface PHPhotoLibrary : NSObject
+ (instancetype)sharedPhotoLibrary;
- (void)performChanges:(void(^)(void))block completionHandler:(void(^)(BOOL, NSError *))handler;
@end

%hook WCSession

- (void)_processScreenshotData:(NSData *)data metadata:(NSDictionary *)metadata {
    NSLog(@"[Legizmo/Screenshot] Intercepted Watch screenshot (%lu bytes)", (unsigned long)data.length);
    %orig;
    // Ensure the photo is written to the library even if the native handler skips it
    if (!data.length) return;
    UIImage *image = [UIImage imageWithData:data];
    if (!image) return;
    [[PHPhotoLibrary sharedPhotoLibrary]
        performChanges:^{ UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil); }
        completionHandler:^(BOOL success, NSError *err) {
            NSLog(@"[Legizmo/Screenshot] Saved to Photos: %@", success ? @"YES" : err.localizedDescription);
        }];
}

%end
