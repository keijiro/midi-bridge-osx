#import <Foundation/Foundation.h>

@class MIDIMessage;

@interface IPCHandler : NSObject
{
    int _inSocket;
    int _outSocket;
    dispatch_source_t _inSource;
    dispatch_source_t _outSource;
}

- (void)sendMessage:(MIDIMessage *)message;

@end
