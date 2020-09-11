#include <cmath>
#include <locale>
#include <codecvt>


#include "../defines.h"
#include "../../vendor/stb/stb_truetype.h"



namespace stbtext:
  FONT_SIZE := 24
  unsigned char font_buffer[24<<20] = {0};
  stbtt_fontinfo font;
  bool did_setup = false

//  void draw_to_terminal(image_data &image, char **text_buffer):
//     for (j=0; j < image.h; ++j):
//        for (i=0; i < image.w; ++i):
//           putchar(" .:ioVM@"[text_buffer[j][i]>>5]);
//        putchar('\n');

  void setup_font():
    if !did_setup:
      #ifdef REMARKABLE
      const char *filename = "/usr/share/fonts/ttf/noto/NotoMono-Regular.ttf";
      #else
      const char *filename = "/usr/share/fonts/truetype/noto/NotoMono-Regular.ttf";
      #endif

     // TODO: fix the max size read to prevent overflows (or just abort on really large files)
      _ := fread(font_buffer, 1, 24<<20, fopen(filename, "rb"));
      stbtt_InitFont(&font, font_buffer, 0);
      did_setup = true


  void draw_bitmap(image_data bitmap, int x, int y, image_data image):
    int i, j, p, q;
    int x_max = x + bitmap.w;
    int y_max = y + bitmap.h;

    for (i = x, p = 0; i < x_max; i++, p++):
      for (j = y, q = 0; j < y_max; j++, q++):
        if (i < 0 || j < 0 || i >= image.w || j >= image.h):
          continue;

        uint32_t val = bitmap.buffer[q * bitmap.w + p];
        image.buffer[j*image.w+i] = val == 0 ? WHITE: BLACK;

  image_data get_text_size(std::string &text, int font_size=FONT_SIZE):
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

  image_data get_text_size(const char* text, int font_size=FONT_SIZE):
    std::string s(text)
    return get_text_size(s, font_size)

  int render_text(std::string &text, image_data &image, int font_size = FONT_SIZE):
    int i,j,ascent,baseline;
    int ch=0;
    float scale=1, xpos=0; // leave a little padding in case the character extends left

    setup_font()
    scale = stbtt_ScaleForPixelHeight(&font, font_size);
    stbtt_GetFontVMetrics(&font, &ascent,0,0);
    baseline = (int) (ascent*scale);

    // TODO: i don't understand this multiplication works. numbers > 12 are mostly good
    // I know its to fit characters without writing over previous letters but
    // there's something strange going on here. 
    unsigned char text_buffer[image.h*font_size][image.w] = {0}
    std::u32string utf32 = std::wstring_convert<std::codecvt_utf8<char32_t>, char32_t>{}.from_bytes(text);

    while utf32[ch]:
       int advance,lsb,x0,y0,x1,y1;
       float x_shift = xpos - (float) floor(xpos);
       stbtt_GetCodepointHMetrics(&font, utf32[ch], &advance, &lsb);
       stbtt_GetCodepointBitmapBox(&font, utf32[ch], scale,scale,&x0,&y0,&x1,&y1);

       offset := (baseline+y0) * image.w + (int)xpos + x0
       stbtt_MakeCodepointBitmapSubpixel(&font, &text_buffer[baseline + y0][(int) xpos + x0], x1-x0,y1-y0, image.w, scale,scale,x_shift,0, utf32[ch]);
       // note that this stomps the old data, so where character boxes overlap (e.g. 'lj') it's wrong
       // because this API is really for baking character bitmaps into textures. if you want to render
       // a sequence of characters, you really need to render each bitmap to a temp font_buffer, then
       // "alpha blend" that into the working font_buffer
       xpos += advance * scale;
       if utf32[ch+1]:
          xpos += scale*stbtt_GetCodepointKernAdvance(&font, utf32[ch],utf32[ch+1]);
       ++ch;

    for j = 0; j < image.h; j++:
      for i = 0; i < image.w; i++:
        uint32_t val = text_buffer[j][i]
        image.buffer[j*image.w+i] = val == 0 ? WHITE: BLACK;

    return 0;

  int render_text(const char *text, image_data &image, int font_size = FONT_SIZE):
    std::string s(text)
    return render_text(s, image, font_size)
