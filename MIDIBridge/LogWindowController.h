#import <Cocoa/Cocoa.h>

@class MIDIMessage;
@class MIDISource;

@interface LogWindowController : NSWindowController

- (void)logIncomingMessage:(MIDIMessage *)message from:(MIDISource *)source;
- (void)logOutgoingMessage:(MIDIMessage *)message;

@end
