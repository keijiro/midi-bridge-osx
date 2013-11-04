#import "MIDISource.h"

@implementation MIDISource

- (id)initWithEndpoint:(MIDIEndpointRef)endpoint
{
    self = [super init];
    if (self) {
        CFStringRef name;
        MIDIObjectGetStringProperty(endpoint, kMIDIPropertyDisplayName, &name);
        self.displayName = (NSString*)CFBridgingRelease(name);
    }
    return self;
}

@end
