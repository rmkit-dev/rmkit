#ifndef DEFINES_H
#define DEFINES_H

#define WHITE 0xFFFFFFFF
#define GRAY 0x07E0
#define BLACK 0

#define WAVEFORM_MODE_DU 0x1
#define TEMP_USE_REMARKABLE_DRAW 0x0018
#define EPDC_FLAG_EXP1 0x270ce20

#ifdef REMARKABLE
// remarkable uses rgb565_le but is grayscale
#define remarkable_color uint16_t
#else
// on linux framebuffer we have 32bit colors
#define remarkable_color uint32_t
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
