#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "../../vendor/stb/image_resize.h"
#include <lodepng.h>
#include <thread>

namespace ui:
  class Thumbnail: public Widget:
    public:
    string filename
    image_data image;
    Thumbnail(int x, y, w, h, string f): Widget(x,y,w,h):
      self.filename = f
      thread *th = new thread([&]() {
        self.load_file()
        ui::MainLoop::refresh()
      });

    void redraw():
      if image.buffer != NULL:
        self.fb->draw_bitmap(self.image, self.x, self.y)
        self.fb->draw_rect(self.x, self.y, self.w, self.h,3,BLACK)

    void load_file():
      char full_path[100]
      unsigned char *load_buffer, *resize_buffer
      vector<unsigned char> raw
      size_t outsize
      unsigned int fw, fh

      sprintf(full_path, "%s/%s", SAVE_DIR, self.filename.c_str())
      load_ret = lodepng_load_file(&load_buffer, &outsize, full_path)
      decode_ret = lodepng::decode(raw, fw, fh, load_buffer, outsize,
                      LodePNGColorType::LCT_GREY, 8);

      num_channels = 1
      resize_len = self.w*self.h*sizeof(unsigned char)*num_channels
      resize_buffer = (unsigned char*)malloc(resize_len)
      memset(resize_buffer, 0, resize_len);
      err = stbir_resize_uint8(raw.data() , fw , fh , 0,
                         resize_buffer, self.w, self.h, 0, num_channels)

      for (int i=0; i< resize_len; i++):
        if resize_buffer[i] != 255:
          resize_buffer[i] = 0

      unsigned char* rgba_buf = (unsigned char*)malloc(4*resize_len)
      j = 0
      for (int i=0; i< resize_len; i++):
        rgba_buf[j++] = resize_buffer[i]
        rgba_buf[j++] = resize_buffer[i]
        rgba_buf[j++] = resize_buffer[i]
        rgba_buf[j++] = resize_buffer[i]

      self.image = image_data{(uint32_t*) rgba_buf, (int) self.w, (int) self.h}
