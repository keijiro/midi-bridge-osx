#import "MIDIBridgeAppDelegate.h"
#import "MIDIMessage.h"
#import "IPCRouter.h"

#pragma mark Private method definition

@interface MIDIBridgeAppDelegate ()

- (void)resetStatus;
- (void)processIncoming:(MIDIMessage *)message;

@property (strong) IPCRouter *ipcHandler;

@end

#pragma mark
#pragma mark Core MIDI callbacks

static void MyMIDIStateChangedHander(const MIDINotification* message, void* refCon)
{
    // Only process additions and removals.
    if (message->messageID != kMIDIMsgObjectAdded && message->messageID != kMIDIMsgObjectRemoved) return;
    
    // Only process source operations.
    const MIDIObjectAddRemoveNotification *addRemoveDetail = (const MIDIObjectAddRemoveNotification *)(message);
    if (addRemoveDetail->childType != kMIDIObjectType_Source) return;
    
    // Reset the client status (on the main thread).
    dispatch_async(dispatch_get_main_queue(), ^{
        MIDIBridgeAppDelegate *delegate = (__bridge MIDIBridgeAppDelegate *)(refCon);
        [delegate resetStatus];
    });
}

static void MyMIDIReadProc(const MIDIPacketList *packetList, void *readProcRefCon, void *srcConnRefCon)
{
    MIDIBridgeAppDelegate *delegate = (__bridge MIDIBridgeAppDelegate *)(readProcRefCon);
    MIDIUniqueID sourceID = *(MIDIUniqueID *)srcConnRefCon;
    
    // Transform the packets into MIDI messages and push it to the message queue.
    const MIDIPacket *packet = &packetList->packet[0];
    for (int packetCount = 0; packetCount < packetList->numPackets; packetCount++) {
        // Extract MIDI messages from the data stream.
        for (int offs = 0; offs < packet->length;) {
            MIDIMessage *message = [[MIDIMessage alloc] initWithSource:sourceID];
            offs = [message readPacket:packet dataOffset:offs];
            [delegate.ipcHandler sendMessage:message];
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate processIncoming:message];
            });
        }
        packet = MIDIPacketNext(packet);
    }
}

#pragma mark

@implementation MIDIBridgeAppDelegate

#pragma mark Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.ipcHandler = [[IPCRouter alloc] initWithReceiver:^(MIDIMessage *message) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self processIncoming:message];
        });
    }];
    
    [self resetStatus];
}

- (void)resetStatus
{
    // Dispose the client if already initialized.
    if (_midiClient) MIDIClientDispose(_midiClient);
    
    // Create a MIDI client.
    MIDIClientCreate(CFSTR("MIDIBridge Client"), MyMIDIStateChangedHander, (__bridge void *)(self), &_midiClient);
    
    // Create a MIDI port which covers all MIDI sources.
    MIDIInputPortCreate(_midiClient, CFSTR("MIDIBridge Input Port"), MyMIDIReadProc, (__bridge void *)(self), &_midiInputPort);
    
    // Enumerate the all MIDI sources.
    ItemCount sourceCount = MIDIGetNumberOfSources();
    NSAssert(sourceCount < sizeof(_sourceIDs) / sizeof(MIDIUniqueID), @"Too many MIDI sources.");
    
    for (int i = 0; i < sourceCount; i++) {
        // Connect the MIDI source to the input port.
        MIDIEndpointRef source = MIDIGetSource(i);
        MIDIObjectGetIntegerProperty(source, kMIDIPropertyUniqueID, &_sourceIDs[i]);
        MIDIPortConnectSource(_midiInputPort, source, &_sourceIDs[i]);
    }

    [self.deviceTable reloadData];
}

- (void)processIncoming:(MIDIMessage *)message
{
    NSString *line = [NSString stringWithFormat:@"%0x %0x %0x %0x", message.sourceID, message.status, message.data1, message.data2];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"]];
    [self.textView.textStorage beginEditing];
    [self.textView.textStorage appendAttributedString:string];
    [self.textView.textStorage endEditing];
    [self.textView scrollRangeToVisible:NSMakeRange(self.textView.string.length, 0)];
}

#pragma mark Table View Data Soruce methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _midiClient ? MIDIGetNumberOfSources() : 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (!_midiClient) return nil;
    
    int columnID = [[tableColumn identifier] intValue];
    
    if (columnID == 2) {
        // 2nd column: shows the display name.
        MIDIObjectRef object;
        MIDIObjectType type;
        MIDIObjectFindByUniqueID(_sourceIDs[row], &object, &type);
        NSAssert(type == kMIDIObjectType_Source, @"Invalid ID.");
        
        CFStringRef name;
        MIDIObjectGetStringProperty(object, kMIDIPropertyDisplayName, &name);
        
        return (NSString*)CFBridgingRelease(name);
    }
    
    // (1st column) show the endpoint ID.
    return [NSString stringWithFormat:@"%0x", _sourceIDs[row]];
}

@end
