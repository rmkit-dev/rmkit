#include <cmath>
#include <locale>
#include <codecvt>
#include <cstring>


#include "../defines.h"
#include "../../vendor/stb/stb_truetype.h"

#if !defined(REMARKABLE) | defined(FONT_EMBED_H)
#ifndef FONT_EMBED_H
#define FONT_EMBED_H "../rmkit/font_embed.h"
#endif

#include FONT_EMBED_H
#endif


#define FONT_SIZE 24
#define FONT_BUFFER_SIZE 24<<20
namespace stbtext:
  // TODO: fix the max size read to prevent overflows (or just abort on really large files)
  extern unsigned char font_buffer[FONT_BUFFER_SIZE] = {}
  extern stbtt_fontinfo font = {}
  extern bool did_setup = false
  extern bool GRAYSCALE = false

  static void setup_font():
    if !did_setup:
      const char *filename = getenv("RMKIT_DEFAULT_FONT");
      bool embedded_font = false
      if filename == NULL:
        #ifdef REMARKABLE
        filename = "/usr/share/fonts/ttf/noto/NotoMono-Regular.ttf";
        #else
        memcpy(font_buffer, FONT_EMBED_NAME, FONT_EMBED_LEN)
        font_buffer[FONT_EMBED_LEN] = 0
        embedded_font = true
        #endif

      if filename:
        FILE * file = fopen(filename, "rb");
        if file == NULL:
          debug "Unable to read font file: ", filename
          return;
        _ := fread(font_buffer, 1, FONT_BUFFER_SIZE, file);
        fclose(file);
      else if !embedded_font:
        debug "No font specified and no embedded font available!"
        return
      stbtt_InitFont(&font, font_buffer, 0);
      did_setup = true


  static void draw_bitmap(image_data bitmap, int x, int y, image_data image):
    int i, j, p, q;
    int x_max = x + bitmap.w;
    int y_max = y + bitmap.h;

    for (i = x, p = 0; i < x_max; i++, p++):
      for (j = y, q = 0; j < y_max; j++, q++):
        if (i < 0 || j < 0 || i >= image.w || j >= image.h):
          continue;

        uint32_t val = bitmap.buffer[q * bitmap.w + p];
        image.buffer[j*image.w+i] = val == 0 ? WHITE: BLACK;

  static int get_line_height(int font_size=FONT_SIZE):
    setup_font()
    float scale = stbtt_ScaleForPixelHeight(&font, font_size)
    int ascent, descent, lineGap
    stbtt_GetFontVMetrics(&font, &ascent, &descent, &lineGap)
    return scale * (ascent - descent + lineGap) + 0.5;

  static image_data get_text_size(std::string &text, int font_size=FONT_SIZE):
    int i,j,ascent,baseline;
    int ch=0;
    float scale=1, xpos=0; // leave a little padding in case the character extends left

    setup_font()
    scale = stbtt_ScaleForPixelHeight(&font, font_size);
    stbtt_GetFontVMetrics(&font, &ascent,0,0);
    baseline = (int) (ascent*scale);

    max_y := 0
    std::u32string utf32 = std::wstring_convert<std::codecvt_utf8<char32_t>, char32_t>{}.from_bytes(text);
    while utf32[ch]:
      int advance,lsb,x0,y0,x1,y1;
      float x_shift = xpos - (float) floor(xpos);
      stbtt_GetCodepointHMetrics(&font, utf32[ch], &advance, &lsb);
      stbtt_GetCodepointBitmapBox(&font, utf32[ch], scale,scale,&x0,&y0,&x1,&y1);
      max_y = std::max(max_y, y1)
      xpos += advance * scale;
      if utf32[ch+1]:
         xpos += scale*stbtt_GetCodepointKernAdvance(&font, utf32[ch],utf32[ch+1]);
      ++ch;

    image_data im = {.buffer=NULL, .w = int(xpos), .h=font_size+baseline}
    return im

  static image_data get_text_size(const char* text, int font_size=FONT_SIZE):
    std::string s(text)
    return get_text_size(s, font_size)

  static int render_text(std::string &text, image_data &image, int font_size = FONT_SIZE):
    int i,j,ascent,baseline;
    int ch=0;
    float scale=1, xpos=0; // leave a little padding in case the character extends left

    setup_font()
    scale = stbtt_ScaleForPixelHeight(&font, font_size);
    stbtt_GetFontVMetrics(&font, &ascent,0,0);
    baseline = (int) (ascent*scale);

    unsigned char *text_buffer = (unsigned char*) calloc(image.h*font_size*image.w, 1);
    std::u32string utf32 = std::wstring_convert<std::codecvt_utf8<char32_t>, char32_t>{}.from_bytes(text);

    while utf32[ch]:
       int advance,lsb,x0,y0,x1,y1;
       float x_shift = xpos - (float) floor(xpos);
       stbtt_GetCodepointHMetrics(&font, utf32[ch], &advance, &lsb);
       stbtt_GetCodepointBitmapBox(&font, utf32[ch], scale,scale,&x0,&y0,&x1,&y1);

       text_pos := (baseline + y0)*image.w + ((int) xpos + x0)

       // if we go above the baseline, re-adjust the starting Y position to 0
       // to prevent crashes.
       // TODO: do this the correct way
       if (baseline + y0) < 0:
         text_pos = (int) xpos + x0

       stbtt_MakeCodepointBitmapSubpixel(&font, &text_buffer[text_pos], x1-x0,y1-y0, image.w, scale,scale,x_shift,0, utf32[ch]);
       // note that this stomps the old data, so where character boxes overlap (e.g. 'lj') it's wrong
       // because this API is really for baking character bitmaps into textures. if you want to render
       // a sequence of characters, you really need to render each bitmap to a temp font_buffer, then
       // "alpha blend" that into the working font_buffer
       xpos += advance * scale;
       if utf32[ch+1]:
          xpos += scale*stbtt_GetCodepointKernAdvance(&font, utf32[ch],utf32[ch+1]);
       ++ch;

    if GRAYSCALE:
      for j = 0; j < image.h; j++:
        for i = 0; i < image.w; i++:
          uint32_t val = text_buffer[j*image.w+i]
          //rescale (0,255) to (31,0) to get gray tones
          image.buffer[j*image.w+i] = color::gray32(31 - (val >> 3));
    else:
      for j = 0; j < image.h; j++:
        for i = 0; i < image.w; i++:
          uint32_t val = text_buffer[j*image.w+i]
          image.buffer[j*image.w+i] = val == 0 ? WHITE: BLACK;

    // TODO: understand why we need to trim the top line
    // to get rid of artifacts above text
    for i = 0; i < image.w; i++:
      image.buffer[i] = WHITE

    free(text_buffer)
    return 0;

  static int render_text(const char *text, image_data &image, int font_size = FONT_SIZE):
    std::string s(text)
    return render_text(s, image, font_size)
