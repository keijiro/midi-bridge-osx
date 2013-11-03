#import "LogWindowController.h"
#import "MIDIMessage.h"

#pragma mark Local functions

static const char *statusByteToCString(Byte b)
{
    static const char *texts[] = {
        "Note Off",
        "Note On",
        "Aftertouch",
        "Control Change",
        "Program Change",
        "Pressure",
        "Pitch Wheel",
        "System"
    };
    return texts[(b >> 4) & 7];
}

#pragma mark
#pragma mark Log window controller class implementation

@implementation LogWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        self.maxLogCount = 32;
        self.inLog = [[NSMutableArray alloc] init];
        self.outLog = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

#pragma mark Logger functions

- (void)logIncomingMessage:(MIDIMessage *)message
{
    [self.inLog insertObject:message atIndex:0];
    if (self.inLog.count > _maxLogCount) [self.inLog removeLastObject];
    [self.inLogTable reloadData];
}

- (void)logOutgoingMessage:(MIDIMessage *)message
{
    [self.outLog insertObject:message atIndex:0];
    if (self.outLog.count > _maxLogCount) [self.outLog removeLastObject];
    [self.outLogTable reloadData];
}

#pragma mark Data source interface for NSTableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (tableView.tag == 0) ? self.inLog.count : self.outLog.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    MIDIMessage *message;
    
    if (tableView.tag == 0) {
        message = [self.inLog objectAtIndex:rowIndex];
    } else {
        message = [self.outLog objectAtIndex:rowIndex];
    }
    
    if ([tableColumn.identifier isEqualToString:@"source"]) {
        return [NSString stringWithFormat:@"%0x", message.sourceID];
    } else if ([tableColumn.identifier isEqualToString:@"channel"]) {
        return [NSString stringWithFormat:@"%d", (message.status & 0xf)];
    } else if ([tableColumn.identifier isEqualToString:@"event"]) {
        return [NSString stringWithUTF8String:statusByteToCString(message.status)];
    } else {
        return [NSString stringWithFormat:@"%d, %d", message.data1, message.data2];
    }
}

@end
