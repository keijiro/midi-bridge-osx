#import <Cocoa/Cocoa.h>

@class MIDIMessage;
@class MIDIEndpoint;

@interface LogWindowController : NSWindowController

- (void)logIncomingMessage:(MIDIMessage *)message from:(MIDIEndpoint *)source;
- (void)logOutgoingMessage:(MIDIMessage *)message;

@end
