#import <signal.h>

static void print_error()
{
	fprintf(stderr, "error: testing host crashed\n");
	exit(70);
}

__attribute__((constructor)) static void installHooks()
{
	// print error message on crash
#ifdef SIGSEGV
	signal (SIGSEGV, print_error);
#endif
#ifdef SIGILL
	signal (SIGILL, print_error);
#endif
#ifdef SIGBUS
	signal (SIGBUS, print_error);
#endif
#ifdef SIGABRT
	signal (SIGABRT, print_error);
#endif
#ifdef SIGFPE
	signal (SIGFPE, print_error);
#endif
}