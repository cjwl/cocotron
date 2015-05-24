/*
 *  partial_stack_blur.h
 *  O2Context_AntiGrain
 *
 *  Created by Airy ANDRE on 21/06/11.
 *  Copyright 2011 plasq. All rights reserved.
 *
 */

#ifndef PARTIAL_BLUR_INCLUDED
#define PARTIAL_BLUR_INCLUDED

#include <agg_blur.h>

// Adapted from stack_blur_rgba32 to allow partial blurring - blame the original for the lack of comments
// Actually just use the alpha value since this function is used to cast shadows
// So we blur the alpha channel of the image, and applied the blured alpha to the "r,g,b,a" color parameter
namespace agg {
//======================================================= partial_stack_blur_rgba32
template <class Img>
void partial_stack_blur_rgba32(Img &img, unsigned radius, unsigned startX, unsigned endX, unsigned startY, unsigned endY, float r, float g, float b, float globalalpha) {
    if(startX >= endX || startY >= endY) {
        // Nothing to do
        return;
    }

    // Clip the rect to the img bounds
    unsigned imgW = img.width();
    unsigned imgH = img.height();
    startX = max(0, startX);
    startY = max(0, startY);
    endX = min(endX, imgW);
    endY = min(endY, imgH);

    typedef typename Img::color_type color_type;
    typedef typename Img::order_type order_type;
    typedef typename Img::value_type value_type;
    typedef typename Img::calc_type calc_type;

    enum order_e {
        R = order_type::R,
        G = order_type::G,
        B = order_type::B,
        A = order_type::A
    };

    unsigned x, y, xp, yp, i;
    unsigned stack_ptr;
    unsigned stack_start;

    const int8u *src_pix_ptr;
    int8u *dst_pix_ptr;
    value_type *stack_pix_ptr;

    unsigned sum_a;
    unsigned sum_in_a;
    unsigned sum_out_a;

    unsigned w = endX;
    unsigned h = endY;
    unsigned wm = w - 1;
    unsigned hm = h - 1;

    unsigned div;
    unsigned mul_sum;
    unsigned shr_sum;

    pod_vector<value_type> stack;

    if(radius > 0) {
        const color_type fillColor = color_type(color_type::base_mask * r, color_type::base_mask * g, color_type::base_mask * b, color_type::base_mask * globalalpha).premultiply();
        const color_type clearColor(0, 0, 0, 0);

        calc_type sr = fillColor.r;
        calc_type sg = fillColor.g;
        calc_type sb = fillColor.b;
        calc_type sa = fillColor.a;

        if(radius > 254)
            radius = 254;
        div = radius * 2 + 1; // center pixels + radius blur on both side
        mul_sum = stack_blur_tables<int>::g_stack_blur8_mul[radius];
        shr_sum = stack_blur_tables<int>::g_stack_blur8_shr[radius];
        stack.allocate(div);

        // Horizontal bluring
        for(y = startY; y < endY; y++) {
            sum_a =
                sum_in_a =
                    sum_out_a = 0;

            src_pix_ptr = img.pix_ptr(startX, y);
            for(i = 0; i <= radius; i++) {
                stack_pix_ptr = &stack[i];
                value_type a = src_pix_ptr[A];
                *stack_pix_ptr = a;
                sum_out_a += a;
                sum_a += a * (i + 1);
            }
            for(i = 1; i <= radius; i++) {
                if(i <= wm)
                    src_pix_ptr += Img::pix_width;
                stack_pix_ptr = &stack[i + radius];
                value_type a = src_pix_ptr[A];
                *stack_pix_ptr = a;
                sum_in_a += a;
                sum_a += a * (radius + 1 - i);
            }

            stack_ptr = radius;
            xp = radius + startX;
            if(xp > wm)
                xp = wm;
            src_pix_ptr = img.pix_ptr(xp, y);
            dst_pix_ptr = img.pix_ptr(startX, y);
            for(x = startX; x < endX; x++) {
                value_type alpha = (sum_a * mul_sum) >> shr_sum;

                // If we are going to push more A with the same currently blurred value, we won't change
                // anything - just go to the next one
                if(alpha == src_pix_ptr[A]) {
                    if(xp >= wm) {
                        break;
                    }
                    if((src_pix_ptr + Img::pix_width)[A] == alpha) {
                        src_pix_ptr += Img::pix_width;
                        dst_pix_ptr += Img::pix_width;
                        ++xp;
                        continue;
                    }
                }
                // We just need to store the alpha blured horizontally
                // The final vertical bluring will store the final value
                dst_pix_ptr[A] = alpha;

                dst_pix_ptr += Img::pix_width;

                sum_a -= sum_out_a;

                stack_start = stack_ptr + div - radius;
                if(stack_start >= div)
                    stack_start -= div;
                stack_pix_ptr = &stack[stack_start];

                sum_out_a -= *stack_pix_ptr;

                if(xp < wm) {
                    src_pix_ptr += Img::pix_width;
                    ++xp;
                }

                value_type a = src_pix_ptr[A];

                *stack_pix_ptr = a;

                sum_in_a += a;
                sum_a += sum_in_a;

                ++stack_ptr;
                if(stack_ptr >= div)
                    stack_ptr = 0;
                stack_pix_ptr = &stack[stack_ptr];

                a = *stack_pix_ptr;
                sum_out_a += a;
                sum_in_a -= a;
            }
        }

        int stride = img.stride();

        // Vertical bluring
        for(x = startX; x < w; x++) {
            sum_a =
                sum_in_a =
                    sum_out_a = 0;

            src_pix_ptr = img.pix_ptr(x, startY);
            for(i = 0; i <= radius; i++) {
                stack_pix_ptr = &stack[i];
                *stack_pix_ptr = src_pix_ptr[A];
                sum_a += src_pix_ptr[A] * (i + 1);
                sum_out_a += src_pix_ptr[A];
            }
            for(i = 1; i <= radius; i++) {
                if(i <= hm)
                    src_pix_ptr += stride;
                stack_pix_ptr = &stack[i + radius];
                *stack_pix_ptr = src_pix_ptr[A];
                sum_a += src_pix_ptr[A] * (radius + 1 - i);
                sum_in_a += src_pix_ptr[A];
            }

            stack_ptr = radius;
            yp = startY + radius;
            if(yp > hm)
                yp = hm;
            src_pix_ptr = img.pix_ptr(x, yp);
            dst_pix_ptr = img.pix_ptr(x, startY);
            for(y = startY; y < h; y++) {
                // Store the final color
                calc_type alpha = ((sum_a * mul_sum) >> shr_sum);
                if(alpha == color_type::base_mask) {
                    *(color_type *)dst_pix_ptr = fillColor;
                } else if(alpha == 0) {
                    *(color_type *)dst_pix_ptr = clearColor;
                } else {
                    dst_pix_ptr[R] = (sr * alpha + color_type::base_mask) >> color_type::base_shift;
                    dst_pix_ptr[G] = (sg * alpha + color_type::base_mask) >> color_type::base_shift;
                    dst_pix_ptr[B] = (sb * alpha + color_type::base_mask) >> color_type::base_shift;
                    dst_pix_ptr[A] = (sa * alpha + color_type::base_mask) >> color_type::base_shift;
                }
                // If we are going to push more A with the same currently blurred value, we won't change
                // anything - just go to the next one
                if(alpha == src_pix_ptr[A]) {
                    if(yp >= hm) {
                        dst_pix_ptr += stride;
                        continue;
                    }
                    if((src_pix_ptr + stride)[A] == alpha) {
                        src_pix_ptr += stride;
                        ++yp;
                        dst_pix_ptr += stride;
                        continue;
                    }
                }

                dst_pix_ptr += stride;

                sum_a -= sum_out_a;

                stack_start = stack_ptr + div - radius;
                if(stack_start >= div)
                    stack_start -= div;

                stack_pix_ptr = &stack[stack_start];
                sum_out_a -= *stack_pix_ptr;

                if(yp < hm) {
                    src_pix_ptr += stride;
                    ++yp;
                }

                value_type a = src_pix_ptr[A];
                *stack_pix_ptr = a;

                sum_in_a += a;
                sum_a += sum_in_a;

                ++stack_ptr;
                if(stack_ptr >= div)
                    stack_ptr = 0;
                stack_pix_ptr = &stack[stack_ptr];

                a = *stack_pix_ptr;
                sum_out_a += a;
                sum_in_a -= a;
            }
        }
    }
}
}

#endif