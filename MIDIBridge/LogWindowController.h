#import <Cocoa/Cocoa.h>

@class MIDIMessage;

@interface LogWindowController : NSWindowController

@property (assign) IBOutlet NSTextView *textView;

- (void)logIncomingMessage:(MIDIMessage *)message;
- (void)logOutgoingMessage:(MIDIMessage *)message;

@end
