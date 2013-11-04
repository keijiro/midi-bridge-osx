#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@interface MIDISource : NSObject
{
    MIDIEndpointRef _endpoint;
}

@property (strong) NSString *displayName;

- (id)initWithEndpoint:(MIDIEndpointRef)endpoint;

@end
