#import <Foundation/Foundation.h>

@class MIDIMessage;
@class MIDIEndpoint;

#pragma mark MIDI client class definition

@interface MIDIClient : NSObject

@property (weak) id delegate;
@property (readonly) NSUInteger sourceCount;
@property (readonly) NSUInteger destinationCount;
@property (assign, nonatomic) NSInteger defaultDestination;

- (id)initWithDelegate:(id)delegate;
- (void)sendMessage:(MIDIMessage *)message;
- (NSString *)getSourceDisplayName:(NSUInteger)number;
- (NSString *)getDestinationDisplayName:(NSUInteger)number;

@end

#pragma mark
#pragma mark Delegate methods for MIDIClient

@interface NSObject (MIDIClientDelegateMethods)
- (void)resetMIDIStatus;
- (void)processIncomingMIDIMessage:(MIDIMessage *)message from:(MIDIEndpoint *)source;
@end
