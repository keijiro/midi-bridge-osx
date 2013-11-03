#import "LogWindowController.h"
#import "MIDIMessage.h"

@implementation LogWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (void)logIncomingMessage:(MIDIMessage *)message
{
    NSString *line = [NSString stringWithFormat:@"from %0x %0x %0x %0x", message.sourceID, message.status, message.data1, message.data2];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"]];
    [self.textView.textStorage beginEditing];
    [self.textView.textStorage appendAttributedString:string];
    [self.textView.textStorage endEditing];
    [self.textView scrollRangeToVisible:NSMakeRange(self.textView.string.length, 0)];
}

- (void)logOutgoingMessage:(MIDIMessage *)message
{
    NSString *line = [NSString stringWithFormat:@"out %0x %0x %0x", message.status, message.data1, message.data2];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:[line stringByAppendingString:@"\n"]];
    [self.textView.textStorage beginEditing];
    [self.textView.textStorage appendAttributedString:string];
    [self.textView.textStorage endEditing];
    [self.textView scrollRangeToVisible:NSMakeRange(self.textView.string.length, 0)];
}

@end
