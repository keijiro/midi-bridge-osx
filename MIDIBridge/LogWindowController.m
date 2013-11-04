#import "LogWindowController.h"
#import "MIDIMessage.h"
#import "MIDIEndpoint.h"

@interface LogWindowController ()

@property (assign) IBOutlet NSTableView *inLogTable;
@property (assign) IBOutlet NSTableView *outLogTable;

@property (assign) NSUInteger maxLogCount;

@property (strong) NSMutableArray *inMessageLog;
@property (strong) NSMutableArray *inSourceLog;
@property (strong) NSMutableArray *outMessageLog;

@end

#pragma mark Local functions

static const char *statusByteToCString(Byte b)
{
    static const char *texts[] = {
        "Note Off",         // 0x8*
        "Note On",          // 0x9*
        "Aftertouch",       // 0xa*
        "Control Change",   // 0xb*
        "Program Change",   // 0xc*
        "Pressure",         // 0xd*
        "Pitch Wheel",      // 0xe*
        "System"            // 0xf*
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
        self.inMessageLog = [[NSMutableArray alloc] init];
        self.inSourceLog = [[NSMutableArray alloc] init];
        self.outMessageLog = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (IBAction)showWindow:(id)sender
{
    // Reload the data before popping up.
    [self.inLogTable reloadData];
    [self.outLogTable reloadData];
    [super showWindow:sender];
}

#pragma mark Logger functions

- (void)logIncomingMessage:(MIDIMessage *)message from:(MIDIEndpoint *)source
{
    [self.inMessageLog insertObject:message atIndex:0];
    [self.inSourceLog insertObject:source atIndex:0];
    if (self.inMessageLog.count > _maxLogCount) {
        [self.inMessageLog removeLastObject];
        [self.inSourceLog removeLastObject];
    }
    // Reload the data only if the window is visible.
    if (self.window.isVisible) [self.inLogTable reloadData];
}

- (void)logOutgoingMessage:(MIDIMessage *)message
{
    [self.outMessageLog insertObject:message atIndex:0];
    if (self.outMessageLog.count > _maxLogCount) {
        [self.outMessageLog removeLastObject];
    }
    // Reload the data only if the window is visible.
    if (self.window.isVisible) [self.outLogTable reloadData];
}

#pragma mark Data source interface for NSTableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return (tableView.tag == 0) ? self.inMessageLog.count : self.outMessageLog.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    if ([tableColumn.identifier isEqualToString:@"source"]) {
        MIDIEndpoint *source = [self.inSourceLog objectAtIndex:rowIndex];
        return [NSString stringWithFormat:@"%@", source.displayName];
    }
    
    MIDIMessage *message;
    
    if (tableView.tag == 0) {
        message = [self.inMessageLog objectAtIndex:rowIndex];
    } else {
        message = [self.outMessageLog objectAtIndex:rowIndex];
    }
    
    if ([tableColumn.identifier isEqualToString:@"channel"]) {
        return [NSString stringWithFormat:@"%d", (message.status & 0xf)];
    } else if ([tableColumn.identifier isEqualToString:@"event"]) {
        return [NSString stringWithUTF8String:statusByteToCString(message.status)];
    } else {
        return [NSString stringWithFormat:@"%d, %d", message.data1, message.data2];
    }
}

@end
