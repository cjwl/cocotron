#import "NSSound_DirectShow.h"
#import <Foundation/NSPathUtilities.h>

@implementation NSSound_DirectShow

static GUID IID_IMediaControl ={ 0x56a868b1, 0x0ad4, 0x11ce,
    0xb0, 0x3a, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70 };
static GUID CLSID_FilterGraph={ 0xe436ebb3, 0x524f, 0x11ce,
    0x9f, 0x53, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70};
static GUID IID_IGraphBuilder={ 0x56a868a9, 0x0ad4, 0x11ce,
    0xb0, 0x3a, 0x00, 0x20, 0xaf, 0x0b, 0xa7, 0x70};

-initWithContentsOfFile:(NSString *)path byReference:(BOOL)byReference {
	if ((self = [super initWithContentsOfFile:path byReference:byReference])) {
		_path = [path copy];
	}
    
    NSLog(@"%s %d",__FILE__,__LINE__);
        
    if (SUCCEEDED(CoCreateInstance(&CLSID_FilterGraph,
                                   NULL,
                                   CLSCTX_INPROC_SERVER,
                                   &IID_IGraphBuilder,
                                   (void **)&_graphBuilder)))
    {
        NSLog(@"%s %d",__FILE__,__LINE__);
        if(_graphBuilder!=NULL){
            NSLog(@"%s %d",__FILE__,__LINE__);
            _graphBuilder->lpVtbl->QueryInterface(_graphBuilder,&IID_IMediaControl, (void **)&_mediaControl);
            NSLog(@"%s %d",__FILE__,__LINE__);
            _graphBuilder->lpVtbl->Release(_graphBuilder);
            NSLog(@"%s %d",__FILE__,__LINE__);
        }
    }
    NSLog(@"%s %d",__FILE__,__LINE__);

	return self;
}

-(BOOL)play {
    NSLog(@"%s %d",__FILE__,__LINE__);
    if(_mediaControl==NULL)
        return NO;
    
    const unichar *soundPathW=[_path fileSystemRepresentationW];
    
    NSLog(@"%s %d",__FILE__,__LINE__);
    HRESULT hr = _mediaControl->lpVtbl->RenderFile(_mediaControl,soundPathW);
    if (SUCCEEDED(hr))
    {
        NSLog(@"%s %d",__FILE__,__LINE__);
        
    }
    NSLog(@"%s %d",__FILE__,__LINE__);
	return YES;
}

-(BOOL)pause {
    NSLog(@"%s %d",__FILE__,__LINE__);
    if(_mediaControl==NULL)
        return NO;
    NSLog(@"%s %d",__FILE__,__LINE__);

    HRESULT hr = _mediaControl->lpVtbl->Pause(_mediaControl);
    NSLog(@"%s %d",__FILE__,__LINE__);
    if (SUCCEEDED(hr))
    {
        NSLog(@"%s %d",__FILE__,__LINE__);
        
    }
    NSLog(@"%s %d",__FILE__,__LINE__);
	return YES;
}

-(BOOL)resume {
    NSLog(@"%s %d",__FILE__,__LINE__);
    if(_mediaControl==NULL)
        return NO;
    NSLog(@"%s %d",__FILE__,__LINE__);

    HRESULT hr = _mediaControl->lpVtbl->Run(_mediaControl);
    NSLog(@"%s %d",__FILE__,__LINE__);
    if (SUCCEEDED(hr))
    {
        NSLog(@"%s %d",__FILE__,__LINE__);
        
    }
    NSLog(@"%s %d",__FILE__,__LINE__);
	return YES;
}

-(BOOL)stop {
    NSLog(@"%s %d",__FILE__,__LINE__);
    if(_mediaControl==NULL)
        return NO;
    NSLog(@"%s %d",__FILE__,__LINE__);

    HRESULT hr = _mediaControl->lpVtbl->Stop(_mediaControl);
    NSLog(@"%s %d",__FILE__,__LINE__);
    if (SUCCEEDED(hr))
    {
        NSLog(@"%s %d",__FILE__,__LINE__);
        
    }
    NSLog(@"%s %d",__FILE__,__LINE__);
	return YES;
}

-(void)dealloc {
    NSLog(@"%s %d",__FILE__,__LINE__);
    if(_mediaControl!=NULL)
        _mediaControl->lpVtbl->Release(_mediaControl);
    NSLog(@"%s %d",__FILE__,__LINE__);
    
	[super dealloc];
}



@end