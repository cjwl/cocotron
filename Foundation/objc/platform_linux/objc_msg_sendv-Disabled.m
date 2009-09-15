
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>
#import <objc/message.h>

id objc_msg_sendv(id self, SEL selector, unsigned arg_size, void *arg_frame)
{
	[NSException raise:@"OBJCForwardingUnavailableException" format:@"Sorry, but objc_msg_sendv and forwarding including NSInvocation are unavailable on this platform."];
	return nil;
}

