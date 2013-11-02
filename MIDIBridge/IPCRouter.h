#import <Foundation/Foundation.h>

@class MIDIMessage;

typedef void (^IPCReceiver)(MIDIMessage *message);

@interface IPCRouter : NSObject
{
    int _inSocket;
    int _outSocket;
    dispatch_source_t _outSource;
    IPCReceiver _receiver;
}

- (id)initWithReceiver:(IPCReceiver)receiver;
- (void)sendMessage:(MIDIMessage *)message;

@end
