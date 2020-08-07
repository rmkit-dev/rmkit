#include "../../vendor/stb/image_resize.h"
#include "../../vendor/lodepng/lodepng.h"
#include "../util/image.h"
#include "pixmap.h"

namespace ui:
  class Thumbnail: public Widget, public ImageCache:
    public:
    string filename
    Thumbnail(int x, y, w, h, string f): Widget(x,y,w,h):
      self.filename = f
      self.image.buffer = NULL
      ui::TaskQueue::add_task([=]() {
        self.get(self.filename)
        self.dirty = 1
      });

    ~Thumbnail():
      if image.buffer != NULL:
        free(image.buffer)
        image.buffer = NULL

    void redraw():
      if image.buffer != NULL:
        self.fb->draw_bitmap(self.image, self.x, self.y)
        self.fb->draw_rect(self.x, self.y, self.w, self.h,3,BLACK)

    image_data fetch(string t):
      if !MainLoop::is_visible(self):
        return image_data({ NULL, 0 })

      char full_path[100]
      unsigned char *load_buffer, *resize_buffer
      vector<unsigned char> raw
      size_t outsize
      unsigned int fw, fh

      sprintf(full_path, "%s/%s", SAVE_DIR, self.filename.c_str())
      load_ret := lodepng_load_file(&load_buffer, &outsize, full_path)
      decode_ret := lodepng::decode(raw, fw, fh, load_buffer, outsize,
                      LodePNGColorType::LCT_GREY, 8);

      buf := (uint32_t*) malloc(fw*fh*sizeof(uint32_t))
      buf = (uint32_t*) memcpy(buf, raw.data(), raw.size())
      self.image = image_data{(uint32_t*) buf, (int) fw, (int) fh}
      util::resize_image(self.image, self.w, self.h)

      return self.image
