#import <Cocoa/Cocoa.h>

@interface MIDIBridgeAppDelegate : NSObject <NSApplicationDelegate>
{
    NSInteger _signalCount;
}

@property (strong) NSMenu *statusMenu;
@property (strong) NSStatusItem *statusItem;

@end
