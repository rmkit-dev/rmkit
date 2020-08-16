#include "../../vendor/stb/stb_image.h"
#include "../../vendor/stb/stb_image_resize.h"
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

    void render():
      if image.buffer != NULL:
          print "RENDERING IMAGE", self.w, self.h, self.image.w, self.image.h
          self.fb->draw_bitmap(self.image, self.x, self.y)
          self.fb->draw_rect(self.x, self.y, self.w, self.h,3,BLACK)

    image_data fetch(string t):
      if !MainLoop::is_visible(self):
        return image_data({ NULL, 0 })

      char full_path[100]
      unsigned char *load_buffer, *resize_buffer
      vector<unsigned char> raw
      size_t outsize
      int fw, fh

      sprintf(full_path, "%s/%s", SAVE_DIR, self.filename.c_str())

      int channels // an output parameter
      decoded := stbi_load(full_path, &fw, &fh, &channels, 1);
      img := image_data{(uint32_t*) decoded, (int) fw, (int) fh}
      util::resize_image(img, self.w, self.h)
      self.image = img

      return self.image
