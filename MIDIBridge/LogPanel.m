#import "LogPanel.h"

@implementation LogPanel

- (void)sendEvent:(NSEvent *)event {
    // Close with pressing down cmd + w.
    if ([event type] == NSKeyDown) {
        if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
            if ([[event charactersIgnoringModifiers] isEqualToString:@"w"]) {
                [self close];
                return;
            }
        }
    }
    [super sendEvent:event];
}

@end
