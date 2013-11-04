#import <Cocoa/Cocoa.h>

@class MIDIMessage;

@interface LogWindowController : NSWindowController

- (void)logIncomingMessage:(MIDIMessage *)message;
- (void)logOutgoingMessage:(MIDIMessage *)message;

@end
