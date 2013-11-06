#import "IPCRouter.h"
#import "MIDIMessage.h"
#import <arpa/inet.h>

#pragma mark Local configuration

#define BRIDGE_PORT 52364

#pragma mark
#pragma mark Private members

@interface IPCRouter () <NSStreamDelegate>
{
    CFSocketRef _socket;
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    Byte buffer[1024];
    NSInteger bufferFilled;
}

- (void)initSocket;
- (void)acceptConnection:(CFSocketNativeHandle)handle;
- (void)closeConnection;

@end

#pragma mark
#pragma mark Callback for Core Foundation socket

static void SocketCallback(CFSocketRef socket, CFSocketCallBackType callbackType, CFDataRef address, const void *data, void *info)
{
    if (callbackType == kCFSocketAcceptCallBack) {
        IPCRouter *router = (__bridge IPCRouter *)(info);
        CFSocketNativeHandle handle = *(CFSocketNativeHandle *)data;
        [router acceptConnection:handle];
    }
}

#pragma mark
#pragma mark Class implementation

@implementation IPCRouter

- (id)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
        [self initSocket];
    }
    return self;
}

- (void)sendMessage:(MIDIMessage *)message
{
    if (_outputStream != nil) {
        const Byte *bytes = message.bytes;
        NSUInteger length = message.length;
        
        Byte packet[4] = {
            bytes[0],
            (length < 2) ? 0xff : bytes[1],
            (length < 3) ? 0xff : bytes[2],
            0xff
        };
        
        NSInteger result = [_outputStream write:packet maxLength:sizeof(packet)];
        
        // Immediately close if there is something wrong.
        if (result < 4) [self closeConnection];
    }
}

#pragma mark Socket initialization

- (void)initSocket
{
    if (_socket == NULL) {
        // A context given for callback.
        CFSocketContext context;
        context.version = 0;
        context.info = (__bridge void *)(self);
        context.retain = NULL;
        context.release = NULL;
        context.copyDescription = NULL;
        
        // Create a socket.
        _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, SocketCallback, &context);
        NSAssert(_socket != NULL, @"Failed to create a socket.");
        
        // Make the socket reusable.
        int flag = 1;
        setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (const void *)&flag, sizeof(flag));
    }
    
    // The address for binding.
    struct sockaddr_in addr;
    bzero(&addr, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(BRIDGE_PORT);
    
    // Bind the socket to the address.
    CFDataRef sincfd = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr, sizeof(addr));
    CFSocketError error = CFSocketSetAddress(_socket, sincfd);
    CFRelease(sincfd);
    
    if (error == noErr) {
        // Add to the runloop.
        CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
    } else {
        // Retry after an interval.
        [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(initSocket) userInfo:nil repeats:NO];
        NSLog(@"Failed to bind the socket. Retry after a second.");
    }
}

#pragma mark Socket open/close

- (void)acceptConnection:(CFSocketNativeHandle)handle
{
    // Close the previous connection.
    if (_inputStream != nil) [self closeConnection];
    
    // Create a pair of streams.
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, handle, &readStream, &writeStream);

    // Set options.
    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    // Cast to Cocoa objects.
    _inputStream = (NSInputStream *)CFBridgingRelease(readStream);
    _outputStream = (NSOutputStream *)CFBridgingRelease(writeStream);
    
    // Schedule the streams in the RunLoop.
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    // Set delegate for the streams.
    _inputStream.delegate = self;
    _inputStream.delegate = self;
    
    // Open the streams.
    [_inputStream open];
    [_outputStream open];
}

- (void)closeConnection
{
    [_inputStream close];
    [_outputStream close];
    
    [_inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    _inputStream = nil;
    _outputStream = nil;
    
    bufferFilled = 0;
}

#pragma mark Socket event handler

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)streamEvent
{
    if (streamEvent == NSStreamEventHasBytesAvailable) {
        // Read data from the socket.
        NSInteger actuallyRead = [_inputStream read:buffer + bufferFilled maxLength:sizeof(buffer) - bufferFilled];

        // Abort if there is something wrong.
        if (actuallyRead < 0) {
            [self closeConnection];
            return;
        }
        
        bufferFilled += actuallyRead;
        
        // Call the delegate for each message.
        NSInteger offset = 0;
        for (; offset + 4 <= bufferFilled; offset += 4) {
            MIDIMessage *message = [[MIDIMessage alloc] init];
            [message readBytes:buffer offset:offset length:offset + 4];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate processIncomingIPCMessage:message];
            });
        }
        
        // Truncate the buffer.
        if (offset == bufferFilled) {
            bufferFilled = 0;
        } else {
            memcpy(buffer, buffer + offset, bufferFilled - offset);
            bufferFilled -= offset;
        }
    }

    // Close if the event is a kind of error.
    if (streamEvent == NSStreamEventEndEncountered || streamEvent == NSStreamEventErrorOccurred) {
        [self closeConnection];
    }
}

@end
