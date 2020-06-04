/* example1.c                                                      */
/*                                                                 */
/* This small program shows how to print a rotated string with the */
/* FreeType 2 library.                                             */

#include <math.h>
#include <stdio.h>
#include <string.h>

#include <ft2build.h>
#include FT_FREETYPE_H

#define FONT_SIZE 32

struct image_data {
  unsigned char* buffer;
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

      image.buffer[j*image.w+i] = bitmap->buffer[q * bitmap->width + p];
    }
  }
  show_image(image);
}

int render_text(char* text, int x, int y, image_data image) {
  FT_Library library;
  FT_Face face;

  FT_GlyphSlot slot;
  FT_Vector pen;    /* untransformed origin  */
  FT_Error error;

  char *filename;
  //char *text;

  int target_height;
  int n, num_chars;

  // filename = argv[1]; /* first argument     */
  filename = "/usr/share/fonts/truetype/noto/NotoMono-Regular.ttf";
  num_chars = strlen(text);
  target_height = image.h;

  error = FT_Init_FreeType(&library); /* initialize library */
  /* error handling omitted */

  error = FT_New_Face(library, filename, 0, &face); /* create face object */
  /* error handling omitted */

  error = FT_Set_Char_Size(face, FONT_SIZE * 64, 0, 100, 0); /* set character size */
  /* error handling omitted */

  /* cmap selection omitted;                                        */
  /* for simplicity we assume that the font contains a Unicode cmap */

  slot = face->glyph;

  pen.x = 0;
  pen.y = target_height;

  int tOffsetY = slot->bitmap_top;
  for (n = 0; n < num_chars; n++) {
    /* load glyph image into the slot (erase previous one) */
    error = FT_Load_Char(face, text[n], FT_LOAD_RENDER);
    if (error)
      continue; /* ignore errors */
    int offsetY = tOffsetY - slot->bitmap_top;
    pen.y += offsetY;
    /* now, draw to our target surface (convert position) */
    draw_bitmap(&slot->bitmap, 
                pen.x / 64,
                pen.y / 64 - slot->bitmap_top + FONT_SIZE,
                //slot->bitmap_left,
                //target_height - slot->bitmap_top,
                image);
    pen.y -= offsetY;

    /* increment pen position */
    pen.x += slot->advance.x;
    pen.y += slot->advance.y;
  }


  FT_Done_Face(face);
  FT_Done_FreeType(library);

  return 0;
}

/* EOF */
