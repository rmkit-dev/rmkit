#ifndef TEXT_H
#define TEXT_H
#include <math.h>
#include <stdio.h>
#include <string.h>

#include <ft2build.h>
#include FT_FREETYPE_H

#include "../defines.h"

namespace freetype {
  struct image_data {
    uint32_t* buffer;
    int w;
    int h;
  };

  void show_image(image_data image) {
    int i, j;

    for (i = 0; i < image.h; i++) {
      for (j = 0; j < image.w; j++)
        putchar(image.buffer[i*image.w+j] == 0 ? ' ' : image.buffer[i*image.w+j] < 128 ? '+' : '*');
      putchar('\n');
    }
  }


  void draw_bitmap(FT_Bitmap *bitmap, FT_Int x, FT_Int y, image_data image) {
    FT_Int i, j, p, q;
    FT_Int x_max = x + bitmap->width;
    FT_Int y_max = y + bitmap->rows;

    /* for simplicity, we assume that `bitmap->pixel_mode' */
    /* is `FT_PIXEL_MODE_GRAY' (i.e., not a bitmap font)   */

    for (i = x, p = 0; i < x_max; i++, p++) {
      for (j = y, q = 0; j < y_max; j++, q++) {
        if (i < 0 || j < 0 || i >= image.w || j >= image.h)
          continue;

        uint32_t val = bitmap->buffer[q * bitmap->width + p];
        image.buffer[j*image.w+i] = val == 0 ? WHITE: BLACK;
      }
    }
  }

  image_data get_text_size(const char *text, int font_size=24) {
    image_data image;

    FT_Library library;
    FT_Face face;

    FT_GlyphSlot slot;
    FT_Vector pen;    /* untransformed origin  */
    FT_Error error;

    const char *filename;

    int target_height;
    int n, num_chars;

    // filename = argv[1]; /* first argument     */
    #ifdef REMARKABLE
    filename = "/usr/share/fonts/ttf/noto/NotoMono-Regular.ttf";
    #else
    filename = "/usr/share/fonts/truetype/noto/NotoMono-Regular.ttf";
    #endif
    num_chars = strlen(text);

    error = FT_Init_FreeType(&library); /* initialize library */
    error = FT_New_Face(library, filename, 0, &face); /* create face object */
    error = FT_Set_Char_Size(face, font_size * 64, 0, 100, 0); /* set character size */

    slot = face->glyph;

    pen.x = 0;
    pen.y = target_height;

    int max_top = 0;
    for (n = 0; n < num_chars; n++) {
      /* load glyph image into the slot (erase previous one) */
      error = FT_Load_Char(face, text[n], FT_LOAD_RENDER);
      if (error)
        continue; /* ignore errors */

      max_top = max_top < slot->bitmap_top ? slot->bitmap_top : max_top;
      /* increment pen position */
      pen.x += slot->advance.x;
      pen.y += slot->advance.y;
    }

    FT_Done_Face(face);
    FT_Done_FreeType(library);

    image.w = pen.x / 64.0;
    image.h = font_size + max_top;
    image.buffer = NULL;
    return image;
  }

  int render_text(char* text, int x, int y, image_data image, int font_size = 24) {
    FT_Library library;
    FT_Face face;

    FT_GlyphSlot slot;
    FT_Vector pen;    /* untransformed origin  */
    FT_Error error;

    const char *filename;

    int target_height;
    int n, num_chars;

    // filename = argv[1]; /* first argument     */
    #ifdef REMARKABLE
    filename = "/usr/share/fonts/ttf/noto/NotoMono-Regular.ttf";
    #else
    filename = "/usr/share/fonts/truetype/noto/NotoMono-Regular.ttf";
    #endif
    num_chars = strlen(text);
    target_height = image.h;

    error = FT_Init_FreeType(&library); /* initialize library */
    error = FT_New_Face(library, filename, 0, &face); /* create face object */
    error = FT_Set_Char_Size(face, font_size * 64, 0, 72, 0); /* set character size */

    slot = face->glyph;

    pen.x = 0;
    pen.y = target_height;

    int tOffsetY = slot->bitmap_top;
    for (n = 0; n < num_chars; n++) {
      /* load glyph image into the slot (erase previous one) */
      error = FT_Load_Char(face, text[n], FT_LOAD_RENDER);
      if (error)
        continue; /* ignore errors */
      pen.y -= slot->bitmap_top;
      draw_bitmap(&slot->bitmap,
                  pen.x / 64,
                  pen.y / 64 - slot->bitmap_top + font_size,
                  image);
      pen.y += slot->bitmap_top;

      /* increment pen position */
      pen.x += slot->advance.x;
      pen.y += slot->advance.y;
    }

    #ifdef DEV
    // show_image(image);
    #endif


    FT_Done_Face(face);
    FT_Done_FreeType(library);

    return 0;
  }
}
#endif
