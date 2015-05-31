#import <objc/dyld.h>

#ifndef MAXPATHLEN
#define MAXPATHLEN 8192
#endif

#if defined(WIN32)

#import <windows.h>


int _NSGetExecutablePath(char *path, uint32_t *capacity) {
    int bufferCapacity = MAXPATHLEN;
    uint16_t buffer[bufferCapacity + 1];
    DWORD i, bufferSize = GetModuleFileNameW(GetModuleHandle(NULL), buffer, bufferCapacity);

    for(i = 0; i < bufferSize; i++)
        if(buffer[i] == '\\')
            buffer[i] = '/';

    int size = WideCharToMultiByte(CP_UTF8, 0, buffer, bufferSize, NULL, 0, NULL, NULL);

    if(size + 1 > *capacity) {
        *capacity = size + 1;
        return -1;
    }

    size = WideCharToMultiByte(CP_UTF8, 0, buffer, bufferSize, path, *capacity, NULL, NULL);
    path[size] = '\0';
    size++;

    *capacity = size;

    return 0;
}

// FIXME: these implementations do not return the size needed

#elif defined(LINUX)

int _NSGetExecutablePath(char *path, uint32_t *capacity) {
    if(*capacity < MAXPATHLEN)
        return MAXPATHLEN;

    if((*capacity = readlink("/proc/self/exe", path, *capacity)) < 0) {
        *capacity = 0;
        return -1;
    }

    return 0;
}

#elif defined(__APPLE__)

extern int _NSGetExecutablePath(char *path, uint32_t *capacity);

#elif defined(BSD)

int _NSGetExecutablePath(char *path, uint32_t *capacity) {
#if defined(FREEBSD)
    if(*capacity < MAXPATHLEN)
        return MAXPATHLEN;

    int mib[4];

    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PATHNAME;
    mib[3] = -1;

    size_t cb = *capacity;

    if(sysctl(mib, 4, path, &cb, NULL, 0) < 0) {
        *capacity = 0;
        return -1;
    }
    *capacity = strlen(path);

    return 0;
#else
    if(*capacity < MAXPATHLEN)
        return MAXPATHLEN;

    int length;

    if((length = readlink("/proc/curproc/file", path, 1024)) < 0) {
        *capacity = 0;
        return -1;
    }
    *capacity = length;

#endif
    return 0;
}

#elif defined(SOLARIS)

int _NSGetExecutablePath(char *path, uint32_t *capacity) {
    if(*capacity < MAXPATHLEN)
        return MAXPATHLEN;

    char probe[MAXPATHLEN + 1];

    sprintf(probe, "/proc/%ld/path/a.out", (long)getpid());

    if((*capacity = readlink(probe, path, *capacity)) < 0) {
        *capacity = 0;
        return -1;
    }

    return 0;
}
#endif
