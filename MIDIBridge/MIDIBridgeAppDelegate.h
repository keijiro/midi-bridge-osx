#import <Cocoa/Cocoa.h>
#import <CoreMIDI/CoreMIDI.h>

@interface MIDIBridgeAppDelegate : NSObject <NSApplicationDelegate>
{
    MIDIClientRef _midiClient;
    MIDIPortRef _midiInputPort;
    MIDIUniqueID _sourceIDs[256];
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *deviceTable;
@property (assign) IBOutlet NSTextView *textView;

@end
