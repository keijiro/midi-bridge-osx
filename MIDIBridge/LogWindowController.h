#import <Cocoa/Cocoa.h>

@class MIDIMessage;

@interface LogWindowController : NSWindowController

@property (assign) IBOutlet NSTableView *inLogTable;
@property (assign) IBOutlet NSTableView *outLogTable;

@property (assign) NSUInteger maxLogCount;
@property (strong) NSMutableArray *inLog;
@property (strong) NSMutableArray *outLog;

- (void)logIncomingMessage:(MIDIMessage *)message;
- (void)logOutgoingMessage:(MIDIMessage *)message;

@end
