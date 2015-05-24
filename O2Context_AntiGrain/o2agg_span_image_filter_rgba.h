// Resample affine filter optimized for non rotated image drawing
// Based on the AGG 2.4 one

//----------------------------------------------------------------------------
// Anti-Grain Geometry - Version 2.4
// Copyright (C) 2002-2005 Maxim Shemanarev (http://www.antigrain.com)
//
// Permission to copy, use, modify, sell and distribute this software
// is granted provided this copyright notice appears in all copies.
// This software is provided "as is" without express or implied
// warranty, and with no claim as to its suitability for any purpose.
//
//----------------------------------------------------------------------------
// Contact: mcseem@antigrain.com
//          mcseemagg@yahoo.com
//          http://www.antigrain.com
//----------------------------------------------------------------------------
//
// Adaptation for high precision colors has been sponsored by
// Liberty Technology Systems, Inc., visit http://lib-sys.com
//
// Liberty Technology Systems, Inc. is the provider of
// PostScript and PDF technology for software developers.
//
//----------------------------------------------------------------------------
#ifndef O2AGG_SPAN_IMAGE_FILTER_RGBA_INCLUDED
#define O2AGG_SPAN_IMAGE_FILTER_RGBA_INCLUDED

#include <agg_basics.h>
#include <agg_color_rgba.h>
#include <agg_span_image_filter_rgb.h>
#include <climits>

#ifdef __SSE2__
#include <emmintrin.h>
#endif

namespace o2agg {
using namespace agg;

#ifdef __SSE2__
static inline __m128i muly(const __m128i &a, const __m128i &b) {
    __m128i tmp1 = _mm_mul_epu32(a, b); /* mul 2,0*/
    __m128i tmp2 = _mm_mul_epu32(_mm_srli_si128(a, 4), _mm_srli_si128(b, 4)); /* mul 3,1 */
    return _mm_unpacklo_epi32(_mm_shuffle_epi32(tmp1, _MM_SHUFFLE(0, 0, 2, 0)), _mm_shuffle_epi32(tmp2, _MM_SHUFFLE(0, 0, 2, 0))); /* shuffle results to [63..0] and pack */
}
#endif

//========================================span_image_resample_rgba_affine
// The idea here is that when we resample a image rendered horizontally, because the renderer works line by line,
// because the resampling algorithm needs to average a few lines, we keep resampling the same lines again and again
// So we keep a buffer of already resampled lines so we process them only once (usually instead of twice)
template <class Source>
class span_image_resample_rgba_affine : public span_image_resample_affine<Source> {
  public:
    typedef Source source_type;
    typedef typename source_type::color_type color_type;
    typedef typename source_type::order_type order_type;
    typedef span_image_resample_affine<source_type> base_type;
    typedef typename base_type::interpolator_type interpolator_type;
    typedef typename color_type::value_type value_type;
    typedef typename color_type::calc_type calc_type;
    typedef typename color_type::long_type long_type;

    typedef span_image_filter<source_type, interpolator_type> type;

    // just because we can't create a pod_array of pod_array of value_type[4]
    typedef struct {
        value_type c[4];
    } pixel_type;

    enum base_scale_e {
        base_shift = color_type::base_shift,
        base_mask = color_type::base_mask,
        downscale_shift = image_filter_shift
    };

    //--------------------------------------------------------------------
    span_image_resample_rgba_affine() {
    }

    span_image_resample_rgba_affine(source_type &src,
        interpolator_type &inter,
        const image_filter_lut &filter)
        : base_type(src, inter, filter), m_straight(false) {
    }

  protected:
    bool m_straight; // true if the transform doesn't rotate the image - needed for the optimized path
    pod_array<pod_array<pixel_type>> m_lines; // scanlines of resampled lines - only on x axis
    pod_array<int32_t> m_linesIdx; // lines idx for the cache line
    // We can use the optimized path only we we're being called with a span with the same x, a y+1 and the same len as
    // the one we used previously - indexed by y%(array size) where y is the line idx in the original image
    int m_baseX; // latest span x received
    int m_idx; // the line to resample
    int m_len;

  public:
    //--------------------------------------------------------------------
    void prepare() {

        span_image_resample_affine<Source>::prepare();

        int diameter = base_type::filter().diameter();
        int ry = diameter * base_type::m_ry;
        int radius_y = (diameter * ry) >> 1;
        int len_y_lr = (diameter * base_type::m_ry + image_subpixel_mask) >> image_subpixel_shift;
        int history_size = len_y_lr * 2;

        m_baseX = -1;
        m_idx = 0;
        // The temp buffers for horizontally resampled lines
        m_lines.resize(history_size);
        // The line number of the original image corresponding to the cached line
        m_linesIdx.resize(history_size);
        for(int i = 0; i < history_size; ++i) {
            m_linesIdx[i] = INT_MIN;
        }

        base_type::interpolator().begin(0, 0, 1);
        int x, y;
        base_type::interpolator().coordinates(&x, &y);
        base_type::interpolator().begin(100, 0, 1);
        int x2, y2;
        base_type::interpolator().coordinates(&x2, &y2);

        m_straight = y == y2;

        m_len = 0;
    }

    void generate(color_type *span, int x, int y, unsigned len) __attribute__((force_align_arg_pointer)) {
        const int kWeightMin = 0;

        // Generate pixels values from (x,y) to (x+len, y)
        int lenOrg = len;
        // Check if we can use our history
        bool useFastPath = m_straight;

        if(useFastPath) {
            int history_size = m_lines.size();

            if(x != m_baseX) {
                // reset things
                m_baseX = x;
                for(int i = 0; i < history_size; ++i) {
                    m_linesIdx[i] = INT_MIN;
                }
            }
            if(len != m_len) {
                // reset things
                m_len = len;
                for(int i = 0; i < history_size; ++i) {
                    m_linesIdx[i] = INT_MIN;
                }
            }
            const int16 *weight_array = base_type::filter().weight_array();

            // Build the missing resampled lines we'll need
            int len2 = len;
            int xOrg = x;
            int yOrg = y;
            int y_lrs[len];
            int y_hrs[len];
            int x_lrs[len];
            int x_hrs[len];

            // First pass to build the missing lines
            {
                base_type::interpolator().begin(xOrg + base_type::filter_dx_dbl(),
                    yOrg + base_type::filter_dy_dbl(), len);

                int diameter = base_type::filter().diameter();
                int filter_scale = diameter << image_subpixel_shift;
                int radius_x = (diameter * base_type::m_rx) >> 1;
                int radius_y = (diameter * base_type::m_ry) >> 1;
                int len_x_lr = (diameter * base_type::m_rx + image_subpixel_mask) >> image_subpixel_shift;
                int len_y_lr = (diameter * base_type::m_ry + image_subpixel_mask) >> image_subpixel_shift;

                int len2 = len;

                for(int idx = 0; idx < len; ++idx) {
                    base_type::interpolator().coordinates(&x, &y);

                    x += base_type::filter_dx_int() - radius_x;
                    y += base_type::filter_dy_int() - radius_y;

                    y_lrs[idx] = y >> image_subpixel_shift;
                    y_hrs[idx] = ((image_subpixel_mask - (y & image_subpixel_mask)) * base_type::m_ry_inv) >> image_subpixel_shift;
                    // Note : if y_lrs/y_hrs is changing during this loop, then we can't run the next for(;;) loop
                    // we could add a check for that - then we should fall back to the slow path
                    if(idx > 0) {
                        y_lrs[idx] = y_lrs[0];
                        y_hrs[idx] = y_hrs[0];
                    }
                    x_lrs[idx] = x >> image_subpixel_shift;
                    x_hrs[idx] = ((image_subpixel_mask - (x & image_subpixel_mask)) * base_type::m_rx_inv) >> image_subpixel_shift;
                    ++base_type::interpolator();
                }
                int y_hr = y_hrs[0];
                int y_lr = y_lrs[0];
                for(;;) {
                    // build a resampled cache of y_lr if needed
                    int weight_y = weight_array[y_hr];
                    if(weight_y > kWeightMin) {
                        int y = y_lr;
                        if(y < 0) {
                            y = 0;
                        }

                        int lineIdx = (y % history_size + history_size) % history_size;
                        if(y != m_linesIdx[lineIdx]) {
                            if(m_lines[lineIdx].size() != lenOrg) {
                                m_lines[lineIdx].resize(lenOrg);
                            }
                            pixel_type *line = m_lines[lineIdx].data();
                            for(int i = 0; i < len; ++i) {
                                int x_hr = x_hrs[i];
                                int x_lr = x_lrs[i];

                                const value_type *fg_ptr = (const value_type *)base_type::source().span(x_lr, y_lr, len_x_lr);
#if !defined(__SSE2__)
                                if(0) {
#else
                                if(o2agg::hasSSE2 && sizeof(color_type) == 4) {
                                    // SSE2 2 RGBA at a time - limited precision on weights but good enough
                                    int total_weight2 = 0;
                                    const __m128i zero = _mm_setzero_si128();
                                    __m128i fg2 = zero;
                                    int x_hr2 = x_hr + base_type::m_rx_inv;

                                    for(;;) {
                                        unsigned weight = weight_array[x_hr];
                                        unsigned weight2 = 0;
                                        if(x_hr2 < filter_scale) {
                                            weight2 = weight_array[x_hr2];
                                        }
                                        // to do : be sure we're aligned, that we have 2 pixels to deal with, and use the right weights for the two pixels
                                        if(weight > kWeightMin || weight2 > kWeightMin) {
                                            weight >>= 12;
                                            weight2 >>= 12;
                                            if(weight2 > 0) {
                                                uint32_t pix = *(uint32_t *)fg_ptr;
                                                fg_ptr = (const value_type *)base_type::source().next_x();
                                                uint32_t pix2 = *(uint32_t *)fg_ptr;
                                                __m128i p = _mm_set_epi32(pix2, pix, pix2, pix);
                                                // Extent the RGBA components to 16 bits by inserting 0 bytes
                                                __m128i rgba = _mm_unpackhi_epi8(p, zero);

                                                __m128i w = _mm_set_epi16(weight2, weight2, weight2, weight2, weight, weight, weight, weight);
                                                // M = RGBA*W - keep the low bytes
                                                __m128i m = _mm_mullo_epi16(rgba, w);
                                                // FG2 = FG2 + RGBA*W
                                                fg2 = _mm_adds_epi16(fg2, m);
                                                total_weight2 += weight2;
                                                total_weight2 += weight;
                                            } else {
                                                uint32_t pix = *(uint32_t *)fg_ptr;
                                                __m128i p = _mm_set_epi32(pix, pix, pix, pix);
                                                // Extent the RGBA components to 16 bits by inserting 0 bytes
                                                __m128i rgba = _mm_unpacklo_epi8(p, zero);

                                                __m128i w = _mm_set_epi16(0, 0, 0, 0, weight, weight, weight, weight);
                                                // M = RGBA*W
                                                __m128i m = _mm_mullo_epi16(rgba, w);
                                                // FG2 = FG2 + RGBA*W
                                                fg2 = _mm_adds_epi16(fg2, m);
                                                fg_ptr = (const value_type *)base_type::source().next_x(); // we've used a second pixel
                                                total_weight2 += weight;
                                            }
                                        }

                                        if(x_hr2 >= filter_scale)
                                            break;
                                        // We just processed two pixels
                                        x_hr += 2 * base_type::m_rx_inv;
                                        if(x_hr >= filter_scale)
                                            break;
                                        x_hr2 += 2 * base_type::m_rx_inv;
                                        fg_ptr = (const value_type *)base_type::source().next_x();
                                    }
                                    if(total_weight2 == 0) {
                                        // Just so the world doesn't crash
                                        total_weight2 = 1;
                                    }
                                    // = add the two halves of fg2 (the two halves are partial sums for RGBA)
                                    __m128i shifted = _mm_srli_si128(fg2, 8);
                                    fg2 = _mm_adds_epi16(fg2, shifted);

                                    uint16_t f[8];
                                    _mm_storeu_si128((__m128i *)f, fg2);
                                    int f0 = f[0] / total_weight2;
                                    int f1 = f[1] / total_weight2;
                                    int f2 = f[2] / total_weight2;
                                    int f3 = f[3] / total_weight2;

                                    // Store in the y_lr cache line, without the "y" weight so we can reuse it width different weights
                                    line->c[0] = (value_type)f0;
                                    line->c[1] = (value_type)f1;
                                    line->c[2] = (value_type)f2;
                                    line->c[3] = (value_type)f3;
                                    line++;
#endif
                                } else {
                                    int total_weight2 = 0;
                                    long_type fg2[4] = {0, 0, 0, 0};
                                    for(;;) {
                                        int weight = weight_array[x_hr];
                                        if(weight > kWeightMin) {
                                            fg2[0] += weight * fg_ptr[0];
                                            fg2[1] += weight * fg_ptr[1];
                                            fg2[2] += weight * fg_ptr[2];
                                            fg2[3] += weight * fg_ptr[3];
                                            total_weight2 += weight;
                                        }
                                        x_hr += base_type::m_rx_inv;
                                        if(x_hr >= filter_scale)
                                            break;
                                        fg_ptr = (const value_type *)base_type::source().next_x();
                                    }
                                    fg2[0] /= total_weight2;
                                    fg2[1] /= total_weight2;
                                    fg2[2] /= total_weight2;
                                    fg2[3] /= total_weight2;

                                    // Store in the y_lr cache line, without the "y" weight so we can reuse it width different weights
                                    line->c[0] = (value_type)fg2[0];
                                    line->c[1] = (value_type)fg2[1];
                                    line->c[2] = (value_type)fg2[2];
                                    line->c[3] = (value_type)fg2[3];
                                    line++;
                                }
                            }
                            m_linesIdx[lineIdx] = y;
                        }
                    }
                    // and move to next line
                    y_hr += base_type::m_ry_inv;

                    if(y_hr >= filter_scale)
                        break;
                    y_lr++;
                }
            }

            // Pass two : do the vertical resampling using the cached lines
            {
                int diameter = base_type::filter().diameter();
                int filter_scale = diameter << image_subpixel_shift;
                int radius_x = (diameter * base_type::m_rx) >> 1;
                int radius_y = (diameter * base_type::m_ry) >> 1;
                int len_x_lr = (diameter * base_type::m_rx + image_subpixel_mask) >> image_subpixel_shift;
                int len_y_lr = (diameter * base_type::m_ry + image_subpixel_mask) >> image_subpixel_shift;

                int y_hr = y_hrs[0];
                // The total weight will be the same for all of the pixels - just compute it once
                int total_weight = 0;
                for(;;) {
                    // y filtering
                    int weight_y = weight_array[y_hr];
                    if(weight_y > kWeightMin) {
                        total_weight += weight_y;
                    }
                    // and move to next line
                    y_hr += base_type::m_ry_inv;

                    if(y_hr >= filter_scale)
                        break;
                }

                int top_ylr;
                int top_yhr;
                for(int i = 0; i < len; ++i) {
                    long_type fg[4] = {0, 0, 0, 0};

                    int y_lr = y_lrs[i];
                    int y_hr = y_hrs[i];

#if !defined(__SSE2__)
                    if(0) {
#else
                    if(o2agg::hasSSE2 && sizeof(color_type) == 4) {
                        // SSE2 2 RGBA at a time - limited precision on weights
                        total_weight = 0;
                        const __m128i zero = _mm_setzero_si128();
                        __m128i fg2 = zero;
                        int y_hr2 = y_hr + base_type::m_ry_inv;
                        int y_lr2 = y_lr + 1;
                        for(;;) {
                            unsigned weight = weight_array[y_hr];
                            unsigned weight2 = 0;
                            if(y_hr2 < filter_scale) {
                                weight2 = weight_array[y_hr2];
                            }
                            // to do : be sure we're aligned, that we have 2 pixels to deal with, and use the right weights for the two pixels
                            if(weight > kWeightMin || weight2 > kWeightMin) {
                                weight >>= 12;
                                weight2 >>= 12;
                                // Weight the pixels on that line
                                int y = y_lr;
                                if(y < 0) {
                                    y = 0;
                                }
                                int lineIdx = (y % history_size + history_size) % history_size;
                                const pixel_type *line1 = m_lines[lineIdx].data();
                                if(weight2 > 0) {
                                    y = y_lr2;
                                    if(y < 0) {
                                        y = 0;
                                    }
                                    lineIdx = (y % history_size + history_size) % history_size;
                                    const pixel_type *line2 = m_lines[lineIdx].data();

                                    uint32_t pix = *(uint32_t *)line1[i].c;
                                    uint32_t pix2 = *(uint32_t *)line2[i].c;
                                    __m128i p = _mm_set_epi32(pix2, pix, pix2, pix);
                                    // Extent the RGBA components to 16 bits by inserting 0 bytes
                                    __m128i rgba = _mm_unpackhi_epi8(p, zero);

                                    __m128i w = _mm_set_epi16(weight2, weight2, weight2, weight2, weight, weight, weight, weight);
                                    // M = RGBA*W - keep the low bytes
                                    __m128i m = _mm_mullo_epi16(rgba, w);
                                    // FG2 = FG2 + RGBA*W
                                    fg2 = _mm_adds_epi16(fg2, m);
                                    total_weight += weight2;
                                    total_weight += weight;
                                } else {
                                    uint32_t pix = *(uint32_t *)line1[i].c;
                                    __m128i p = _mm_set_epi32(pix, pix, pix, pix);
                                    // Extent the RGBA components to 16 bits by inserting 0 bytes
                                    __m128i rgba = _mm_unpacklo_epi8(p, zero);

                                    __m128i w = _mm_set_epi16(0, 0, 0, 0, weight, weight, weight, weight);
                                    // M = RGBA*W
                                    __m128i m = _mm_mullo_epi16(rgba, w);
                                    // FG2 = FG2 + RGBA*W
                                    fg2 = _mm_adds_epi16(fg2, m);
                                    total_weight += weight;
                                }
                            }

                            if(y_hr2 >= filter_scale)
                                break;
                            // We just processed two pixels
                            y_hr += 2 * base_type::m_ry_inv;
                            if(y_hr >= filter_scale)
                                break;
                            y_hr2 += 2 * base_type::m_ry_inv;

                            y_lr += 2;
                            y_lr2 += 2;
                        }
                        if(total_weight == 0) {
                            // Just so the world doesn't crash
                            total_weight = 1;
                        }

                        // = add the two halves of fg2 (the two halves are partial sums for RGBA)
                        __m128i shifted = _mm_srli_si128(fg2, 8);
                        fg2 = _mm_adds_epi16(fg2, shifted);

                        uint16_t f[8];
                        _mm_storeu_si128((__m128i *)f, fg2);
                        fg[0] = f[0];
                        fg[1] = f[1];
                        fg[2] = f[2];
                        fg[3] = f[3];
#endif
                    } else {
                        for(;;) {
                            // y filtering
                            int weight_y = weight_array[y_hr];
                            if(weight_y > kWeightMin) {
                                // Weight the pixels on that line
                                int y = y_lr;
                                if(y < 0) {
                                    y = 0;
                                }
                                int lineIdx = (y % history_size + history_size) % history_size;

                                const pixel_type *line = m_lines[lineIdx].data();

                                // accumulate the cached value to the resampling buffer
                                fg[0] += (calc_type)line[i].c[0] * weight_y;
                                fg[1] += (calc_type)line[i].c[1] * weight_y;
                                fg[2] += (calc_type)line[i].c[2] * weight_y;
                                fg[3] += (calc_type)line[i].c[3] * weight_y;
                            }
                            // and move to next line
                            y_hr += base_type::m_ry_inv;

                            if(y_hr >= filter_scale)
                                break;
                            y_lr++;
                        }
                    }
                    // All of the samples needed to build this pixel have been weighted - we're done
                    fg[0] /= total_weight;
                    fg[1] /= total_weight;
                    fg[2] /= total_weight;
                    fg[3] /= total_weight;

                    if(fg[order_type::A] > base_mask)
                        fg[order_type::A] = base_mask;
                    if(fg[order_type::R] > fg[order_type::A])
                        fg[order_type::R] = fg[order_type::A];
                    if(fg[order_type::G] > fg[order_type::A])
                        fg[order_type::G] = fg[order_type::A];
                    if(fg[order_type::B] > fg[order_type::A])
                        fg[order_type::B] = fg[order_type::A];

                    span->r = (value_type)fg[order_type::R];
                    span->g = (value_type)fg[order_type::G];
                    span->b = (value_type)fg[order_type::B];
                    span->a = (value_type)fg[order_type::A];

                    // Move to next pixel
                    ++span;
                }
            }
        }
    slowpath:
        if(useFastPath == false) {
            // Slower path - that's the original resample filter code
            base_type::interpolator().begin(x + base_type::filter_dx_dbl(),
                y + base_type::filter_dy_dbl(), len);

            int diameter = base_type::filter().diameter();
            int filter_scale = diameter << image_subpixel_shift;
            int radius_x = (diameter * base_type::m_rx) >> 1;
            int radius_y = (diameter * base_type::m_ry) >> 1;
            int len_x_lr = (diameter * base_type::m_rx + image_subpixel_mask) >> image_subpixel_shift;

            const int16 *weight_array = base_type::filter().weight_array();
            do {
                base_type::interpolator().coordinates(&x, &y);

                x += base_type::filter_dx_int() - radius_x;
                y += base_type::filter_dy_int() - radius_y;

                long_type fg[4] = {image_filter_scale / 2, image_filter_scale / 2, image_filter_scale / 2, image_filter_scale / 2};

                int y_lr = y >> image_subpixel_shift;
                int y_hr = ((image_subpixel_mask - (y & image_subpixel_mask)) * base_type::m_ry_inv) >> image_subpixel_shift;
                int total_weight = 0;
                int x_lr = x >> image_subpixel_shift;
                int x_hr = ((image_subpixel_mask - (x & image_subpixel_mask)) * base_type::m_rx_inv) >> image_subpixel_shift;

                int x_hr2 = x_hr;
                const value_type *fg_ptr = (const value_type *)base_type::source().span(x_lr, y_lr, len_x_lr);
                for(;;) {
                    int weight_y = weight_array[y_hr];
                    x_hr = x_hr2;
                    for(;;) {
                        int weight = (weight_y * weight_array[x_hr] + image_filter_scale / 2) >> downscale_shift;

                        fg[0] += fg_ptr[0] * weight;
                        fg[1] += fg_ptr[1] * weight;
                        fg[2] += fg_ptr[2] * weight;
                        fg[3] += fg_ptr[3] * weight;
                        total_weight += weight;
                        x_hr += base_type::m_rx_inv;
                        if(x_hr >= filter_scale)
                            break;
                        fg_ptr = (const value_type *)base_type::source().next_x();
                    }
                    y_hr += base_type::m_ry_inv;
                    if(y_hr >= filter_scale)
                        break;
                    fg_ptr = (const value_type *)base_type::source().next_y();
                }
                fg[0] /= total_weight;
                fg[1] /= total_weight;
                fg[2] /= total_weight;
                fg[3] /= total_weight;

                if(fg[0] < 0)
                    fg[0] = 0;
                if(fg[1] < 0)
                    fg[1] = 0;
                if(fg[2] < 0)
                    fg[2] = 0;
                if(fg[3] < 0)
                    fg[3] = 0;

                if(fg[order_type::A] > base_mask)
                    fg[order_type::A] = base_mask;
                if(fg[order_type::R] > fg[order_type::A])
                    fg[order_type::R] = fg[order_type::A];
                if(fg[order_type::G] > fg[order_type::A])
                    fg[order_type::G] = fg[order_type::A];
                if(fg[order_type::B] > fg[order_type::A])
                    fg[order_type::B] = fg[order_type::A];

                span->r = (value_type)fg[order_type::R];
                span->g = (value_type)fg[order_type::G];
                span->b = (value_type)fg[order_type::B];
                span->a = (value_type)fg[order_type::A];

                ++span;
                ++base_type::interpolator();
            } while(--len);
        }
    }
};
}

#endif
