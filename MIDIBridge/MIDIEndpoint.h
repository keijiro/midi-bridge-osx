#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@interface MIDIEndpoint : NSObject

@property (strong) NSString *displayName;

- (id)initWithEndpointRef:(MIDIEndpointRef)endpoint;

@end
