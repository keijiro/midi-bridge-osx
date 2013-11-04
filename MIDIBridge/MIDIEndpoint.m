#import "MIDIEndpoint.h"

@implementation MIDIEndpoint

- (id)initWithEndpointRef:(MIDIEndpointRef)endpoint
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
