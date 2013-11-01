#import <Foundation/Foundation.h>

@class MIDIMessage;

typedef void (^IPCHandlerReceiveHandler)(MIDIMessage *message);

@interface IPCHandler : NSObject
{
    int _inSocket;
    int _outSocket;
    dispatch_source_t _outSource;
    IPCHandlerReceiveHandler _receiveHandler;
}

- (void)sendMessage:(MIDIMessage *)message;
- (void)registerReceiveHandler:(IPCHandlerReceiveHandler)block;

@end
