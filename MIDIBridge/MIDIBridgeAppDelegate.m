#import "MIDIBridgeAppDelegate.h"
#import "MIDIClient.h"
#import "IPCRouter.h"
#import "LogWindowController.h"

#pragma mark Private members

@interface MIDIBridgeAppDelegate ()
{
    MIDIClient *_midiClient;
    IPCRouter *_ipcRouter;
    LogWindowController *_logWindowController;
    
    NSStatusItem *_statusItem;
    NSInteger _signalCount;
}
@end

#pragma mark
#pragma mark Application delegate class implementation

@implementation MIDIBridgeAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _midiClient = [[MIDIClient alloc] initWithDelegate:self];
    _ipcRouter = [[IPCRouter alloc] initWithDelegate:self];
    _logWindowController = [[LogWindowController alloc] initWithWindowNibName:@"LogWindow"];
    
    // Create a status item and its menu.
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    _statusItem.menu = [self statusMenuWithCurrentState];
    _statusItem.image = [NSImage imageNamed:@"Status"];
    _statusItem.alternateImage = [NSImage imageNamed:@"StatusHighlighted"];
    _statusItem.highlightMode = YES;
    
    [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(updateIndicator) userInfo:nil repeats:YES];
}

#pragma mark UI actions

- (void)openLogView:(id)sender
{
    [_logWindowController showWindow:nil];
}

- (void)selectSourceItem:(id)sender
{
}

- (void)selectDestinationItem:(id)sender
{
    _midiClient.defaultDestination = [sender tag];
    _statusItem.menu = [self statusMenuWithCurrentState];
}

#pragma mark MIDIClient delegate methods

- (void)resetMIDIStatus
{
    _statusItem.menu = [self statusMenuWithCurrentState];
}

- (void)processIncomingMIDIMessage:(MIDIMessage *)message from:(MIDIEndpoint *)source
{
    [_ipcRouter sendMessage:message];
    [_logWindowController logIncomingMessage:message from:source];
    _signalCount++;
}

#pragma mark IPCRouter delegate methods

- (void)processIncomingIPCMessage:(MIDIMessage *)message
{
    [_midiClient sendMessage:message];
    [_logWindowController logOutgoingMessage:message];
    _signalCount++;
}

#pragma mark Status menu handlers

- (NSMenu *)statusMenuWithCurrentState
{
    NSMenu *menu = [[NSMenu alloc] init];
    
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Open Log Viewer..." action:@selector(openLogView:) keyEquivalent:@""]];
    [menu addItem:[NSMenuItem separatorItem]];
    
    if (_midiClient.sourceCount == 0) {
        [menu addItem:[[NSMenuItem alloc] initWithTitle:@"No MIDI Sources" action:NULL keyEquivalent:@""]];
    } else {
        [menu addItem:[[NSMenuItem alloc] initWithTitle:@"MIDI Sources" action:NULL keyEquivalent:@""]];
        for (NSUInteger i = 0; i < _midiClient.sourceCount; i++) {
            [menu addItem:[[NSMenuItem alloc] initWithTitle:[_midiClient getSourceDisplayName:i] action:@selector(selectSourceItem:) keyEquivalent:@""]];
        }
    }
    [menu addItem:[NSMenuItem separatorItem]];
    
    if (_midiClient.destinationCount == 0) {
        [menu addItem:[[NSMenuItem alloc] initWithTitle:@"No MIDI Destinations" action:NULL keyEquivalent:@""]];
    } else {
        [menu addItem:[[NSMenuItem alloc] initWithTitle:@"MIDI Destinations" action:NULL keyEquivalent:@""]];
        for (NSUInteger i = 0; i < _midiClient.destinationCount; i++) {
            NSMenuItem *item =[[NSMenuItem alloc] initWithTitle:[_midiClient getDestinationDisplayName:i] action:@selector(selectDestinationItem:) keyEquivalent:@""];
            item.tag = i;
            if (i == _midiClient.defaultDestination) item.state = NSOnState;
            [menu addItem:item];
        }
    }
    [menu addItem:[NSMenuItem separatorItem]];
    
    [menu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit MIDIBridge" action:@selector(terminate:) keyEquivalent:@""]];
    
    return menu;
}

- (void)updateIndicator
{
    NSString *imageName = (_signalCount == 0) ? @"Status" : @"StatusActive";
    _statusItem.image = [NSImage imageNamed:imageName];
    _signalCount = 0;
}

@end
