
#import <Foundation/NSDebug.h>
#import <SenTestingKit/SenTestingKit.h>

int main(int argc,const char *argv[])
{
   NSInitializeProcess(argc, argv);
   NSZombieEnabled=YES;
   id pool=[NSAutoreleasePool new];
   [SenTestProbe runTestsAtUnitPath:[[NSBundle mainBundle] bundlePath] scope:nil];
   [pool release];
}