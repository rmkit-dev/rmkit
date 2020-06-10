#ifndef DEFINES_H
#define DEFINES_H

#define WHITE remarkable_color(0x000FFFFF)
#define GRAY remarkable_color(0x4444)
#define BLACK remarkable_color(0)
#define ERASER remarkable_color(0x93)

#define WAVEFORM_MODE_DU 0x1
#define WAVEFORM_MODE_GC16 0x2
#define WAVEFORM_MODE_GC4 0x3
#define WAVEFORM_MODE_A2 0x4
#define WAVEFORM_MODE_DU4 0x7
#define WAVEFORM_MODE_AUTO 257
#define TEMP_USE_REMARKABLE_DRAW 0x0018
#define EPDC_FLAG_EXP1 0x270ce20

#define EPDC_FLAG_USE_DITHERING_ALPHA 0x3ff00000

#ifdef REMARKABLE
// remarkable uses rgb565_le but is grayscale
#define remarkable_color uint8_t
#define pointer_size uint32_t
#else
// on linux framebuffer we have 32bit colors
#define remarkable_color uint32_t
#define pointer_size uint64_t
#endif



#define MTWIDTH 767
#define MTHEIGHT 1023
#define WACOMWIDTH 15725.0
#define WACOMHEIGHT 20967.0
#define DISPLAYWIDTH 1404
#define DISPLAYHEIGHT 1872.0
#define MT_X_SCALAR (float(DISPLAYWIDTH) / float(MTWIDTH));
#define MT_Y_SCALAR (float(DISPLAYHEIGHT) / float(MTHEIGHT));
#define WACOM_X_SCALAR (float(DISPLAYWIDTH) / float(WACOMWIDTH));
#define WACOM_Y_SCALAR (float(DISPLAYHEIGHT) / float(WACOMHEIGHT));

#endif
