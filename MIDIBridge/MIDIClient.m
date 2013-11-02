#import "MIDIClient.h"
#import "MIDIMessage.h"

#pragma mark Private method declaration

@interface MIDIClient(PrivateMethod)
- (void)reset;
@end

#pragma mark
#pragma mark Core MIDI callbacks

static void StateChangedHander(const MIDINotification* message, void* refCon)
{
    MIDIClient *client = (__bridge MIDIClient *)(refCon);
    
    // Only process additions and removals.
    if (message->messageID != kMIDIMsgObjectAdded && message->messageID != kMIDIMsgObjectRemoved) return;
    
    // Only process source and destination operations.
    const MIDIObjectAddRemoveNotification *addRemoveDetail = (const MIDIObjectAddRemoveNotification *)(message);
    if (addRemoveDetail->childType != kMIDIObjectType_Source && addRemoveDetail->childType != kMIDIObjectType_Destination) return;
    
    // Reset the client status.
    [client reset];
    
    // Call the delegate method (on the main thread).
    dispatch_async(dispatch_get_main_queue(), ^{
        [client.delegate resetMIDIStatus];
    });
}

static void ReadProc(const MIDIPacketList *packetList, void *readProcRefCon, void *srcConnRefCon)
{
    MIDIClient *client = (__bridge MIDIClient *)(readProcRefCon);
    MIDIUniqueID sourceID = *(MIDIUniqueID *)srcConnRefCon;
    
    // Transform the packets into MIDI messages and push it to the message queue.
    const MIDIPacket *packet = &packetList->packet[0];
    for (int packetCount = 0; packetCount < packetList->numPackets; packetCount++) {
        // Extract MIDI messages from the data stream.
        for (int offs = 0; offs < packet->length;) {
            MIDIMessage *message = [[MIDIMessage alloc] initWithSource:sourceID];
            offs = [message readPacket:packet dataOffset:offs];
            // Call the delegate method.
            dispatch_async(dispatch_get_main_queue(), ^{
                [client.delegate processIncomingMIDIMessage:message];
            });
        }
        packet = MIDIPacketNext(packet);
    }
}

#pragma mark
#pragma mark MIDI Client class implementation

@implementation MIDIClient

- (id)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        [self reset];
    }
    return self;
}

- (void)reset
{
    // Dispose the client if already initialized.
    if (_midiClient) MIDIClientDispose(_midiClient);
    
    // Create a MIDI client.
    MIDIClientCreate(CFSTR("MIDIBridge Client"), StateChangedHander, (__bridge void *)(self), &_midiClient);
    
    // Create two MIDI ports for input and output.
    MIDIInputPortCreate(_midiClient, CFSTR("MIDIBridge Input Port"), ReadProc, (__bridge void *)(self), &_midiInputPort);
    MIDIOutputPortCreate(_midiClient, CFSTR("MIDIBridge Output Port"), &_midiOutputPort);
    
    // Enumerate the all MIDI sources.
    ItemCount sourceCount = MIDIGetNumberOfSources();
    NSAssert(sourceCount < sizeof(_sourceIDs) / sizeof(MIDIUniqueID), @"Too many MIDI sources.");
    
    for (int i = 0; i < sourceCount; i++) {
        // Connect the MIDI source to the input port.
        MIDIEndpointRef source = MIDIGetSource(i);
        MIDIObjectGetIntegerProperty(source, kMIDIPropertyUniqueID, &_sourceIDs[i]);
        MIDIPortConnectSource(_midiInputPort, source, &_sourceIDs[i]);
    }
    
    // FIXME: choose a default destination properly.
    _defaultDestination = -1;
}

- (void)sendMessage:(MIDIMessage *)message
{
    if (_defaultDestination >= 0) {
        Byte buffer[32];
        MIDIPacketList *packetList = (MIDIPacketList *)buffer;
        MIDIPacket *packet = MIDIPacketListInit(packetList);
        
        UInt32 data = message.packedData;
        MIDIPacketListAdd(packetList, sizeof(buffer), packet, 0, 3, (Byte*)&data);
        
        MIDISend(_midiOutputPort, MIDIGetDestination(self.defaultDestination), packetList);
    }
}

#pragma mark Property accessors

- (NSUInteger)sourceCount
{
    return MIDIGetNumberOfSources();
}

- (NSUInteger)destinationCount
{
    return MIDIGetNumberOfDestinations();
}

- (NSString *)getSourceDisplayName:(NSUInteger)number
{
    CFStringRef name;
    MIDIObjectGetStringProperty(MIDIGetSource(number), kMIDIPropertyDisplayName, &name);
    return (NSString*)CFBridgingRelease(name);
}

- (NSString *)getDestinationDisplayName:(NSUInteger)number
{
    CFStringRef name;
    MIDIObjectGetStringProperty(MIDIGetDestination(number), kMIDIPropertyDisplayName, &name);
    return (NSString*)CFBridgingRelease(name);
}

@end
