//
//  MDIJKSDLView.m
//  IJKMediaPlayer
//
//  Created by ashqal on 16/7/13.
//  Copyright © 2016年 bilibili. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IJKSDLGLView.h"

#ifdef MD360PlayerMode
#import "MDExt.h"
#include "ijksdl/ijksdl_timer.h"

struct SDL_VoutOverlay_Opaque {
    SDL_mutex *mutex;
    CVPixelBufferRef pixel_buffer;
    Uint16 pitches[AV_NUM_DATA_POINTERS];
    Uint8 *pixels[AV_NUM_DATA_POINTERS];
};
@interface IJKSDLGLView()<MDIJKSDLGLView>{
    int             _frameCount;
    int64_t         _lastFrameTime;

}

@property (nonatomic,weak) id<MDVideoFrameCallback> callback;
@property (nonatomic,strong) UILabel* label;
@end

@implementation IJKSDLGLView

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
#ifdef MDFPS
        self.label = [[UILabel alloc]initWithFrame:CGRectMake(0, frame.size.height - 20, 200, 20)];
        self.label.font = [UIFont systemFontOfSize:17];
        [self.label setText:@"fps"];
        [self.label setTextColor:[UIColor colorWithWhite:1 alpha:1]];
        [self addSubview:self.label];
#endif
    }
    return self;
}

- (void) display: (SDL_VoutOverlay *) overlay{

    if ([self.callback respondsToSelector:@selector(onFrameAvailable:)]) {
        MDVideoFrame* frame = malloc(sizeof(MDVideoFrame));

        frame -> w = overlay->w;
        frame -> h = overlay->h;
        frame -> format = overlay->format;
        frame -> planes = overlay->planes;
        frame -> pitches = overlay->pitches;
        frame -> pixels = overlay->pixels;
        frame ->buffer = NULL;
        if (frame->format == SDL_FCC__VTB && overlay->opaque != NULL && overlay->opaque->pixel_buffer != NULL) {
            frame->buffer = ((SDL_VoutOverlay_Opaque*)overlay->opaque)->pixel_buffer;
            CVBufferRetain(frame->buffer);
        }

        [self.callback onFrameAvailable:(frame)];

        if (frame ->buffer != NULL) {
            CVBufferRelease(frame->buffer);
        }
        free(frame);


    }

    [self countFps];
#ifdef MDFPS
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.label setText:[NSString stringWithFormat:@"fps:%f",self.fps]];
    });
#endif

}

- (void) countFps{
    int64_t current = (int64_t)SDL_GetTickHR();
    int64_t delta   = (current > _lastFrameTime) ? current - _lastFrameTime : 0;
    if (delta <= 0) {
        _lastFrameTime = current;
    } else if (delta >= 1000) {
        _fps = ((CGFloat)_frameCount) * 1000 / delta;
        _frameCount = 0;
        _lastFrameTime = current;
    } else {
        _frameCount++;
    }
}

- (UIImage*) snapshot{
    return nil;
}

- (void)setHudValue:(NSString *)value forKey:(NSString *)key{
    // nop

}

- (void) setFrameCallback:(id<MDVideoFrameCallback>) callback{
    self.callback = callback;
}

@end
#endif
