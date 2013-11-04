#import "MIDIBridgeAppDelegate.h"
#import "MIDIMessage.h"
#import "MIDIClient.h"
#import "IPCRouter.h"
#import "LogWindowController.h"

#pragma mark Private properties

@interface MIDIBridgeAppDelegate ()
@property (strong) MIDIClient *midiClient;
@property (strong) IPCRouter *ipcRouter;
@property (strong) LogWindowController *logWindowController;
@end

#pragma mark
#pragma mark Application delegate class implementation

@implementation MIDIBridgeAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.midiClient = [[MIDIClient alloc] initWithDelegate:self];
    self.ipcRouter = [[IPCRouter alloc] initWithDelegate:self];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.logWindowController = [[LogWindowController alloc] initWithWindowNibName:@"LogWindow"];

    [self resetMIDIStatus];
    
    [NSTimer scheduledTimerWithTimeInterval:0.25f target:self selector:@selector(updateIndicator) userInfo:nil repeats:YES];
}

#pragma mark UI Actions

- (void)openLogView:(id)sender
{
    [self.logWindowController showWindow:nil];
}

- (void)selectSourceItem:(id)sender
{
}

- (void)selectDestinationItem:(id)sender
{
    self.midiClient.defaultDestination = [sender tag];
    [self resetMIDIStatus];
}

- (void)updateIndicator
{
    NSString *imageName = (_signalCount == 0) ? @"Status" : @"StatusActive";
    self.statusItem.image = [NSImage imageNamed:imageName];
    _signalCount = 0;
}

#pragma mark MIDIClient delegate methods

- (void)resetMIDIStatus
{
    self.statusMenu = [[NSMenu alloc] init];
    [self.statusItem setMenu:self.statusMenu];
    
    self.statusItem.image = [NSImage imageNamed:@"Status"];
    self.statusItem.alternateImage = [NSImage imageNamed:@"StatusHighlighted"];
    [self.statusItem setHighlightMode:YES];
    
    [self.statusMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Open Log Viewer..." action:@selector(openLogView:) keyEquivalent:@""]];
    
    [self.statusMenu addItem:[NSMenuItem separatorItem]];
    
    if (self.midiClient.sourceCount == 0) {
        [self.statusMenu addItem:[[NSMenuItem alloc] initWithTitle:@"No MIDI Sources" action:NULL keyEquivalent:@""]];
    } else {
        [self.statusMenu addItem:[[NSMenuItem alloc] initWithTitle:@"MIDI Sources" action:NULL keyEquivalent:@""]];
        for (NSUInteger i = 0; i < self.midiClient.sourceCount; i++) {
            [self.statusMenu addItem:[[NSMenuItem alloc] initWithTitle:[self.midiClient getSourceDisplayName:i] action:@selector(selectSourceItem:) keyEquivalent:@""]];
        }
    }
    
    [self.statusMenu addItem:[NSMenuItem separatorItem]];

    if (self.midiClient.destinationCount == 0) {
        [self.statusMenu addItem:[[NSMenuItem alloc] initWithTitle:@"No MIDI Destinations" action:NULL keyEquivalent:@""]];
    } else {
        [self.statusMenu addItem:[[NSMenuItem alloc] initWithTitle:@"MIDI Destinations" action:NULL keyEquivalent:@""]];
        for (NSUInteger i = 0; i < self.midiClient.destinationCount; i++) {
            NSMenuItem *item =[[NSMenuItem alloc] initWithTitle:[self.midiClient getDestinationDisplayName:i] action:@selector(selectDestinationItem:) keyEquivalent:@""];
            item.tag = i;
            if (i == self.midiClient.defaultDestination) item.state = NSOnState;
            [self.statusMenu addItem:item];
        }
    }

    [self.statusMenu addItem:[NSMenuItem separatorItem]];
    [self.statusMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit MIDIBridge" action:@selector(terminate:) keyEquivalent:@""]];
}

- (void)processIncomingMIDIMessage:(MIDIMessage *)message from:(MIDISource *)source
{
    [self.ipcRouter sendMessage:message];
    [self.logWindowController logIncomingMessage:message from:source];
    _signalCount++;
}

#pragma mark IPCRouter delegate methods

- (void)processIncomingIPCMessage:(MIDIMessage *)message
{
    [self.midiClient sendMessage:message];
    [self.logWindowController logOutgoingMessage:message];
    _signalCount++;
}

@end
