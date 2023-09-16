#include "widget.h"
#include "layouts.h"
#include "text.h"
#include "../util/image.h"
#include "../../vendor/stb/stb_image.h"

#include <dirent.h>

namespace ui:
  class ImageCache:
    public:
    static map<string, image_data> CACHE = {}
    image_data image = { NULL, 0 }
    ImageCache():
      pass

    virtual image_data get(string name):
      it := CACHE.find(name)
      if it == CACHE.end():
        im := self.fetch(name)
        if im.buffer != NULL:
          CACHE[name] = im
          self.image = im
      else:
        self.image = it->second

      return self.image


    virtual image_data fetch(string t) { return { NULL, 0 }; };

  class CachedIcon: public icons::Icon, public ImageCache:
    public:
    int width = -1, height = -1

    CachedIcon(unsigned char *d, int l):
      self.data = d
      self.len = l
      return

    CachedIcon(unsigned char *d, int l, const char* n):
      self.data = d
      self.len = l
      self.name = n
      self.get(self.name)
      return

    CachedIcon(unsigned char *d, int l, const char* n, int w, int h):
      self.data = d
      self.len = l
      self.name = n
      self.width = w
      self.height = h
      char buf[PATH_MAX]
      i := sprintf(buf, "%s:%i:%i", n, w, h)
      buf[i] = 0

      self.get(string(buf))

      return

    ~CachedIcon():
      if self.name == NULL && self.image.buffer != NULL:
        free(self.image.buffer)


    image_data fetch(string t):
      if self.data == NULL:
        return image_data({ NULL, 0 })
      if self.image.buffer != NULL:
        return self.image

      int iconw = 0
      int iconh = 0
      int channels

      buf := stbi_load_from_memory(self.data, self.len, &iconw, &iconh, &channels, 1)
      self.image = image_data{(uint32_t*) buf, (int) iconw, (int) iconh, 1}

      if self.width > 0 && self.height > 0:
        util::resize_image(self.image, self.width, self.height, 20 /* black threshold */)
      return self.image

  class Pixmap: public Widget:
    public:
    CachedIcon icon = {NULL, 0}
    remarkable_color alpha = 97
    Pixmap(int x, y, w, h, icons::Icon ico): Widget(x,y,w,h):
      self.icon = CachedIcon({ico.data, (int) ico.len, ico.name, self.w, self.h})

    tuple<int, int> get_render_size():
      if self.icon.image.buffer != NULL:
        return self.icon.image.w, self.icon.image.h

      return 0, 0

    void render():
      if self.icon.data == NULL || self.icon.image.buffer == NULL:
        return

      fb->draw_bitmap(self.icon.image, x, y, self.alpha, false)
