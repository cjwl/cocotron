#include "Foundation/Foundation.h"


@interface Hello:NSObject
{
}


+ world;


- (void)greetz;


@end


@implementation Hello:NSObject


+ world
{
    return [[[self alloc] init] autorelease];
}


- (void)greetz
{
    printf("Hallo Welt!\n");
}


- (long long)forwardTest
{
    return 123456789012LL;
}


//- forwardSelector: (SEL)sel arguments: (void *)args
//{
//    IMP imp = class_getMethodImplementation(isa, @selector(forwardTest)); //(id)((int)[self forwardTest]);
//    return imp(self, @selector(forwardTest));
//}


- (int)invocation: (char)a1 test: (char *)a2 method: (long long)a3
{
    fprintf(stdout, "original with %c, %s, %lld\n", a1, a2, a3);
    return 123456789;
}


- (long long)iinvocation: (char)a1 test: (char *)a2 method: (long long)a3
{
    fprintf(stdout, "original with %c, %s, %lld\n", a1, a2, a3);
    return 123456789012345678LL;
}


@end


@interface Dummy:NSObject


- (id)foo;


@end


@implementation Dummy:NSObject


- (id)foo
{
    return nil;
}


- (char)bar
{
    return 0;
}


- (long long)huh
{
    return 0;
}


- (int)invocation: (char)a1 test: (char *)a2 method: (long long)a3
{
    fprintf(stdout, "dummy with %c, %s, %lld\n", a1, a2, a3);
    return 987654321;
}


- (long long)iinvocation: (char)a1 test: (char *)a2 method: (long long)a3
{
    fprintf(stdout, "dummy with %c, %s, %lld\n", a1, a2, a3);
    return 987654321098765432LL;
}


@end

#ifdef __clang__
@interface Blocker:NSObject

+ (NSString *)doSomethingWith: (NSString *(^)(NSString *))block;

@end

@implementation Blocker


+ (NSString *)doSomethingWith: (NSString *(^)(NSString *))block
{
    return [NSString stringWithFormat: @"The block output: %@", block(@"the block argument")];
}


@end
#endif


int main(int argc, char **argv)
{
    id pool = [[NSAutoreleasePool alloc] init];
    [[Hello world] greetz];
    NSLog(@"Hallo echte Welt!");
    //NSLog(@"-- %lld --", [[Hello world] bar]);
    //NSLog(@"-- %lld --", [[Hello world] foo]);
    //NSLog(@"-- %lld --", [[Hello world] huh]);
    //NSLog(@"-- %lld --", [[Hello world] performSelector: NSSelectorFromString(@"nix")]);
    //NSLog(@"-- %lld --", [[Hello world] performSelector: NSSelectorFromString(@"bar")]);
    SEL sel = @selector(iinvocation:test:method:);
    NSInvocation *i = [NSInvocation invocationWithMethodSignature: [[Hello world] methodSignatureForSelector: sel]];
    //int r;
    long long r = 1;
    char a1 = 'x';
    char *a2 = "Hallo du";
    long long a3 = 1234567890123456LL;
    [i setSelector: sel];
    [i setArgument: &a1 atIndex: 2];
    [i setArgument: &a2 atIndex: 3];
    [i setArgument: &a3 atIndex: 4];
    //[i invokeWithTarget: [Hello world]];
    [i invokeWithTarget: [[[Dummy alloc] init] autorelease]];
    [i getReturnValue: &r];
    //NSLog(@"invocation returned %d", r);
    printf("invocation returned %lld\n", r);

#ifdef __clang__
    NSLog(@"Lucky you! Now I will try something with blocks …");
    NSLog(@"The call with block output: %@", [Blocker doSomethingWith: ^(NSString *arg){
        return [NSString stringWithFormat: @"The block got: %@", arg];
    }]);
#else
    NSLog(@"You did not compile with clang … be assured that you are missing something.");
#endif

    [pool release];
    return 0;
}
