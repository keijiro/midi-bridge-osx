#import "MIDIClient.h"
#import "MIDIMessage.h"
#import "MIDIEndpoint.h"

#pragma mark Private members

@interface MIDIClient ()
{
    MIDIClientRef _midiClient;
    MIDIPortRef _midiInputPort;
    MIDIPortRef _midiOutputPort;
    NSMutableArray *_sources;
}

- (void)reset;

@end

#pragma mark
#pragma mark Core MIDI callbacks

static void StateChangedHander(const MIDINotification* message, void* refCon)
{
    MIDIClient *client = (__bridge MIDIClient *)(refCon);
    
    // Only process following events.
    // - Source additions and removals.
    // - Destination additions and removals.
    // - Setup change event.
    if (message->messageID == kMIDIMsgObjectAdded || message->messageID == kMIDIMsgObjectRemoved) {
        const MIDIObjectAddRemoveNotification *addRemoveDetail = (const MIDIObjectAddRemoveNotification *)(message);
        if (addRemoveDetail->childType != kMIDIObjectType_Source && addRemoveDetail->childType != kMIDIObjectType_Destination) {
            return;
        }
    } else if (message->messageID != kMIDIMsgSetupChanged) {
        return;
    }
    
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
    MIDIEndpoint *source = (__bridge MIDIEndpoint *)(srcConnRefCon);
    
    // Transform the packets into MIDI messages and push it to the message queue.
    const MIDIPacket *packet = &packetList->packet[0];
    for (int packetCount = 0; packetCount < packetList->numPackets; packetCount++) {
        // Extract MIDI messages from the data stream.
        for (NSUInteger offs = 0; offs < packet->length;) {
            MIDIMessage *message = [[MIDIMessage alloc] init];
            offs = [message readPacket:packet offset:offs];
            // Call the delegate method.
            dispatch_async(dispatch_get_main_queue(), ^{
                [client.delegate processIncomingMIDIMessage:message from:source];
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

- (void)dealloc
{
    if (_midiClient) MIDIClientDispose(_midiClient);
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
    _sources = [[NSMutableArray alloc] initWithCapacity:sourceCount];
    
    for (int i = 0; i < sourceCount; i++) {
        MIDIEndpointRef endpoint = MIDIGetSource(i);
        MIDIEndpoint *source = [[MIDIEndpoint alloc] initWithEndpointRef:endpoint];
        [_sources addObject:source];
        // Connect the MIDI source to the input port.
        MIDIPortConnectSource(_midiInputPort, endpoint, (__bridge void *)(source));
    }
    
    // Retrieve the destination setting.
    SInt32 uidDestination = (SInt32)[[NSUserDefaults standardUserDefaults] integerForKey:@"DefaultDestination"];

    // Look for the destination which has the same unique ID.
    ItemCount destinationCount = MIDIGetNumberOfDestinations();
    _defaultDestination = -1;
    for (int i = 0; i < destinationCount; i++) {
        SInt32 uid;
        MIDIObjectGetIntegerProperty(MIDIGetDestination(i), kMIDIPropertyUniqueID, &uid);
        if (uid == uidDestination) {
            _defaultDestination = i;
            break;
        }
    }
}

- (void)sendMessage:(MIDIMessage *)message
{
    if (_defaultDestination >= 0) {
        Byte buffer[32];
        MIDIPacketList *packetList = (MIDIPacketList *)buffer;
        MIDIPacket *packet = MIDIPacketListInit(packetList);
        MIDIPacketListAdd(packetList, sizeof(buffer), packet, 0, message.length, message.bytes);
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
    MIDIEndpoint *source = [_sources objectAtIndex:number];
    return source.displayName;
}

- (NSString *)getDestinationDisplayName:(NSUInteger)number
{
    CFStringRef name;
    MIDIObjectGetStringProperty(MIDIGetDestination(number), kMIDIPropertyDisplayName, &name);
    return (NSString*)CFBridgingRelease(name);
}

- (void)setDefaultDestination:(NSInteger)destination
{
    _defaultDestination = destination;
    
    // Store the unique ID for the future use.
    SInt32 uid;
    MIDIObjectGetIntegerProperty(MIDIGetDestination(destination), kMIDIPropertyUniqueID, &uid);
    [[NSUserDefaults standardUserDefaults] setInteger:uid forKey:@"DefaultDestination"];
}

@end
