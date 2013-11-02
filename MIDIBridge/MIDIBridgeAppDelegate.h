#import <Cocoa/Cocoa.h>

@interface MIDIBridgeAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *deviceTable;
@property (assign) IBOutlet NSTextView *textView;

@end
