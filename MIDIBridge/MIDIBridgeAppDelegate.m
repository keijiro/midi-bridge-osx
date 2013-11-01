#import "MIDIBridgeAppDelegate.h"
#import "MIDIMessage.h"
#import <arpa/inet.h>

#pragma mark Configuration

#define MIDI_IN_PORT 52364
#define MIDI_OUT_PORT 52365

#pragma mark Private method definition

@interface MIDIBridgeAppDelegate ()

- (void)resetStatus;
- (void)processIncoming:(MIDIMessage *)message;

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

#pragma mark
#pragma mark Memo :)

#if 0
// Create the MIDI-in socket.
{
    _inSocket = socket(AF_INET, SOCK_DGRAM, 0);
    NSAssert(_inSocket >= 0, @"Failed to create a socket (%d).", errno);
    
    struct sockaddr_in addr;
    bzero(&addr, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = 0;
    
    int err = bind(_inSocket, (struct sockaddr *)&addr, sizeof(addr));
    NSAssert(err == 0, @"Failed to bind a socket (%d).", errno);
}

// Create the MIDI-out socket.
{
    _outSocket = socket(AF_INET, SOCK_DGRAM, 0);
    NSAssert(_outSocket >= 0, @"Failed to create a socket (%d).", errno);
    
    struct sockaddr_in addr;
    bzero(&addr, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(MIDI_OUT_PORT);
    
    int err = bind(_outSocket, (struct sockaddr *)&addr, sizeof(addr));
    NSAssert(err == 0, @"Failed to bind a socket (%d).", errno);
}

// Uses the default queue to dispatching.
dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

// Start the MIDI-in handler.
_inSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, defaultQueue);
dispatch_source_set_timer(_inSource, DISPATCH_TIME_NOW, NSEC_PER_SEC / 3, NSEC_PER_SEC / 2);
{
    // sockaddr for MIDI-in.
    struct sockaddr_in addr;
    bzero(&addr, sizeof(addr));
    addr.sin_family = AF_INET;
    inet_aton("127.0.0.1", &(addr.sin_addr));
    addr.sin_port = htons(MIDI_IN_PORT);
    
    // Other local variables for the handler.
    __block int counter = 0;
    
    // The handler block.
    dispatch_source_set_event_handler(_inSource, ^{
        char buffer[256];
        snprintf(buffer, sizeof(buffer), "Hooray! %d", counter);
        sendto(_inSocket, buffer, strlen(buffer), MSG_DONTWAIT, (struct sockaddr *)&addr, sizeof(addr));
        counter++;
    });
}
dispatch_resume(_inSource);

// Start the MIDI-out handler.
_outSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, _outSocket, 0, defaultQueue);
dispatch_source_set_event_handler(_outSource, ^{
    char buffer[1024];
    size_t estimated = dispatch_source_get_data(_outSource);
    recv(_outSocket, buffer, estimated, 0);
    buffer[estimated] = 0;
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:[[NSString stringWithUTF8String:buffer] stringByAppendingString:@"\n"]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView.textStorage beginEditing];
        [self.textView.textStorage appendAttributedString:string];
        [self.textView.textStorage endEditing];
        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.string.length, 0)];
    });
});
dispatch_resume(_outSource);
#endif
