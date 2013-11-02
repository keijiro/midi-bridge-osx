#import <Foundation/Foundation.h>

@class MIDIMessage;

#pragma mark IPC router class definition

@interface IPCRouter : NSObject
{
    int _inSocket;
    int _outSocket;
    dispatch_source_t _outSource;
}

@property (weak) id delegate;

- (id)initWithDelegate:(id)delegate;
- (void)sendMessage:(MIDIMessage *)message;

@end

#pragma mark
#pragma mark Delegate methods for IPCRouter

@interface NSObject(IPCRouterDelegateMethods)
- (void)processIncomingIPCMessage:(MIDIMessage *)message;
@end
