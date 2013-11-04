#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@interface MIDISource : NSObject

@property (strong) NSString *displayName;

- (id)initWithEndpoint:(MIDIEndpointRef)endpoint;

@end
