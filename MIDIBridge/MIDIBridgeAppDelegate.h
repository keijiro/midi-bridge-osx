#import <Cocoa/Cocoa.h>
#import <CoreMIDI/CoreMIDI.h>

@interface MIDIBridgeAppDelegate : NSObject <NSApplicationDelegate>
{
    MIDIClientRef _midiClient;
    MIDIPortRef _midiInputPort;
    MIDIPortRef _midiOutputPort;
    MIDIUniqueID _sourceIDs[64];
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *deviceTable;
@property (assign) IBOutlet NSTextView *textView;

@end
