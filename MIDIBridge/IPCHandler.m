#import "IPCHandler.h"
#import "MIDIMessage.h"
#import <arpa/inet.h>

#pragma mark Configuration

#define MIDI_IN_PORT 52364
#define MIDI_OUT_PORT 52365

#pragma mark

@implementation IPCHandler

- (id)init
{
    self = [super init];
    if (self) {
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
        
        UInt32 data = message.packedData;
        sendto(_inSocket, &data, sizeof(data), MSG_DONTWAIT, (struct sockaddr *)&addr, sizeof(addr));
    });
}

@end

#pragma mark
#pragma mark Memo :)

#if 0

// Uses the default queue to dispatching.
dispatch_queue_t defaultQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

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
