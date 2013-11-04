#import "IPCRouter.h"
#import "MIDIMessage.h"
#import <arpa/inet.h>

#pragma mark Local configuration

#define MIDI_IN_PORT 52364
#define MIDI_OUT_PORT 52365

#pragma mark
#pragma mark IPC router class implementation

@implementation IPCRouter

- (id)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        
        // Create the MIDI-in socket.
        {
            _inSocket = socket(AF_INET, SOCK_DGRAM, 0);
            NSAssert(_inSocket >= 0, @"Failed to create a socket (%d).", errno);
            
            struct sockaddr_in addr;
            bzero(&addr, sizeof(addr));
            addr.sin_family = AF_INET;
            addr.sin_addr.s_addr = htonl(INADDR_ANY);
            addr.sin_port = 0;
            
            int err __attribute__((unused)) = bind(_inSocket, (struct sockaddr *)&addr, sizeof(addr));
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
            
            int err __attribute__((unused)) = bind(_outSocket, (struct sockaddr *)&addr, sizeof(addr));
            NSAssert(err == 0, @"Failed to bind a socket (%d).", errno);
        }

        // Start the MIDI-out handler.
        dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _outSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, _outSocket, 0, defaultQueue);
        dispatch_source_set_event_handler(_outSource, ^{
            size_t estimated = dispatch_source_get_data(_outSource);
            Byte buffer[estimated];
            recv(_outSocket, buffer, estimated, 0);
            
            MIDIMessage *message = [[MIDIMessage alloc] init];
            [message readBytes:buffer length:estimated];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate processIncomingIPCMessage:message];
            });
        });
        dispatch_resume(_outSource);
    }
    return self;
}

- (void)sendMessage:(MIDIMessage *)message
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        // sockaddr for MIDI-in.
        struct sockaddr_in addr;
        bzero(&addr, sizeof(addr));
        addr.sin_family = AF_INET;
        inet_aton("127.0.0.1", &(addr.sin_addr));
        addr.sin_port = htons(MIDI_IN_PORT);
        // Send the data.
        sendto(_inSocket, message.bytes, message.length, MSG_DONTWAIT, (struct sockaddr *)&addr, sizeof(addr));
    });
}

@end
