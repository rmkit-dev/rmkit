#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "../../vendor/stb/image_resize.h"
#include <lodepng.h>

namespace ui:
  class Thumbnail: public Widget:
    public:
    string filename
    image_data image;
    Thumbnail(int x, y, w, h, string f): Widget(x,y,w,h):
      self.filename = f

      char full_path[100]
      unsigned char *load_buffer, *resize_buffer
      vector<unsigned char> raw
      size_t outsize
      unsigned int fw, fh

      sprintf(full_path, "%s/%s", SAVE_DIR, self.filename.c_str())
      load_ret = lodepng_load_file(&load_buffer, &outsize, full_path)
      decode_ret = lodepng::decode(raw, fw, fh, load_buffer, outsize)

      num_channels = 4
      resize_len = self.w*self.h*sizeof(unsigned char)*num_channels
      resize_buffer = (unsigned char*)malloc(resize_len)
      memset(resize_buffer, 0, resize_len);
      err = stbir_resize_uint8(raw.data() , fw , fh , 0,\
                         resize_buffer, self.w, self.h, 0, num_channels /* this is wrong? */)

      self.image = image_data{(uint32_t*) resize_buffer, (int) self.w, (int) self.h}

    void redraw():
      self.fb->draw_bitmap(self.image, self.x, self.y)
      self.fb->draw_rect(self.x, self.y, self.w, self.h,3,BLACK)

