#include "../../vendor/stb/stb_image.h"
#include "../../vendor/stb/stb_image_resize.h"
#include "../util/image.h"
#include "../fb/fb.h"
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
      self.undraw()
      if image.buffer != NULL:
          self.fb->draw_bitmap(self.image, self.x, self.y, framebuffer::ALPHA_BLEND, 0)
          self.fb->waveform_mode = WAVEFORM_MODE_AUTO

    image_data fetch(string t):
      if !MainLoop::is_visible(self):
        return image_data({ NULL, 0 })

      unsigned char *load_buffer, *resize_buffer
      vector<unsigned char> raw
      size_t outsize
      int fw, fh



      int channels // an output parameter
      decoded := stbi_load(self.filename.c_str(), &fw, &fh, &channels, 4);
      img := image_data{(uint32_t*) decoded, (int) fw, (int) fh, 4}
      util::resize_image(img, self.w, self.h)
      self.image = img

      return self.image
