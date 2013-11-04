#import "LogPanel.h"

@implementation LogPanel

- (void)sendEvent:(NSEvent *)event {
    // Close on pressing cmd-w.
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
