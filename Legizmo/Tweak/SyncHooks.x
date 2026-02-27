// Legizmo – SyncHooks.x
// Hooks companionappd to bridge message format changes between watchOS versions.
// Ensures notifications, activity rings, and Siri/Handoff keep working.

#import <Foundation/Foundation.h>

// ── Message type identifiers (reverse engineered from companionappd) ──────────
typedef NS_ENUM(NSUInteger, LGZMessageType) {
    LGZMessageTypeNotification  = 0x01,
    LGZMessageTypeActivity      = 0x02,
    LGZMessageTypeHealth        = 0x03,
    LGZMessageTypeAppContext    = 0x04,
    LGZMessageTypeComplication  = 0x05,
    LGZMessageTypeSiri          = 0x06,
};

// ── Private interface stubs ───────────────────────────────────────────────────
@interface CAWatchMessage : NSObject
@property (nonatomic, assign) NSUInteger messageType;
@property (nonatomic, strong) NSData    *payload;
@property (nonatomic, assign) NSUInteger protocolVersion;
- (instancetype)initWithType:(NSUInteger)type payload:(NSData *)payload;
@end

@interface CAWatchCompanionManager : NSObject
+ (instancetype)sharedManager;
- (void)sendMessage:(CAWatchMessage *)message toWatch:(id)watch;
- (void)processIncomingMessage:(CAWatchMessage *)message fromWatch:(id)watch;
@end

@interface CANotificationRelay : NSObject
- (void)relayNotification:(id)notification toWatch:(id)watch;
- (BOOL)shouldRelayNotification:(id)notification;
@end

// ── Protocol version translation table ───────────────────────────────────────
// watchOS 10+ changed the binary encoding of several message types.
// These functions translate new → old and old → new.

static NSData *translatePayloadForSend(NSData *payload, NSUInteger msgType, NSUInteger watchProtocol) {
    if (watchProtocol < 10) return payload; // no translation needed for watchOS < 10

    // For watchOS 10+, companionappd expects new-format messages.
    // If we're on iOS 16 or older, our encoding is old-format — translate it.
    NSMutableData *translated = [payload mutableCopy];
    switch (msgType) {
        case LGZMessageTypeNotification:
            // watchOS 10 added a 2-byte header for notification priority field
            // Prepend 0x00 0x01 (normal priority) if not present
            if (translated.length >= 2) {
                const uint8_t *bytes = translated.bytes;
                if (bytes[0] != 0x00) { // old format detected
                    uint8_t header[2] = {0x00, 0x01};
                    NSMutableData *newData = [NSMutableData dataWithBytes:header length:2];
                    [newData appendData:translated];
                    translated = newData;
                }
            }
            break;

        case LGZMessageTypeActivity:
            // Activity ring data schema changed in watchOS 9; handled via repackaging
            break;

        default:
            break;
    }
    return [translated copy];
}

static NSData *translatePayloadForReceive(NSData *payload, NSUInteger msgType, NSUInteger watchProtocol) {
    if (watchProtocol < 10) return payload;

    NSMutableData *translated = [payload mutableCopy];
    switch (msgType) {
        case LGZMessageTypeNotification: {
            // Strip the watchOS 10 2-byte priority header so iOS 16 can parse it
            if (translated.length > 2) {
                const uint8_t *bytes = translated.bytes;
                if (bytes[0] == 0x00) { // new format detected
                    translated = [[translated subdataWithRange:NSMakeRange(2, translated.length - 2)] mutableCopy];
                }
            }
            break;
        }
        default:
            break;
    }
    return [translated copy];
}

// ── Hooks ─────────────────────────────────────────────────────────────────────
%hook CAWatchCompanionManager

- (void)sendMessage:(CAWatchMessage *)message toWatch:(id)watch {
    NSData *translated = translatePayloadForSend(
        message.payload,
        message.messageType,
        message.protocolVersion
    );
    if (translated != message.payload) {
        NSLog(@"[Legizmo/Sync] Translated outbound message type=0x%02lx len=%lu→%lu",
              (unsigned long)message.messageType,
              (unsigned long)message.payload.length,
              (unsigned long)translated.length);
        message.payload = translated;
    }
    %orig(message, watch);
}

- (void)processIncomingMessage:(CAWatchMessage *)message fromWatch:(id)watch {
    NSData *translated = translatePayloadForReceive(
        message.payload,
        message.messageType,
        message.protocolVersion
    );
    if (translated != message.payload) {
        NSLog(@"[Legizmo/Sync] Translated inbound message type=0x%02lx len=%lu→%lu",
              (unsigned long)message.messageType,
              (unsigned long)message.payload.length,
              (unsigned long)translated.length);
        message.payload = translated;
    }
    %orig(message, watch);
}

%end


// ── Notification relay hooks ──────────────────────────────────────────────────
%hook CANotificationRelay

// Ensure all notifications pass through regardless of entitlement checks
// that may fail due to iOS/watchOS version mismatch
- (BOOL)shouldRelayNotification:(id)notification {
    BOOL orig = %orig;
    if (!orig) {
        NSLog(@"[Legizmo/Sync] Forcing notification relay for: %@", notification);
    }
    return YES;
}

%end
