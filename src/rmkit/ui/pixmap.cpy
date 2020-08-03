#include "widget.h"
#include "layouts.h"
#include "text.h"

namespace ui:
  class ImageCache:
    public:
    static map<string, image_data> CACHE
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

  map<string, image_data> ImageCache::CACHE = {}


  class CachedIcon: public icons::Icon, public ImageCache:
    public:

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

    ~CachedIcon():
      if self.name == NULL && self.image.buffer != NULL:
        free(self.image.buffer)


    image_data fetch(string t):
      if self.data == NULL:
        return image_data({ NULL, 0 })
      if self.image.buffer != NULL:
        return self.image

      unsigned int iconw = 0
      unsigned int iconh = 0
      vector<unsigned char> out
      uint32_t* buf

      lodepng::decode(out, iconw, iconh, self.data, self.len)
      buf = (uint32_t*) malloc(iconw*iconh*sizeof(uint32_t))
      buf = (uint32_t*) memcpy(buf, out.data(), out.size())
      self.image = image_data{(uint32_t*) buf, (int) iconw, (int) iconh}
      return self.image



  class Pixmap: public Widget:
    public:
    CachedIcon icon = {NULL, 0}
    Pixmap(int x, y, w, h, icons::Icon ico): Widget(x,y,w,h):
      self.icon = CachedIcon({ico.data, (int) ico.len, ico.name})

    tuple<int, int> get_render_size():
      if self.icon.image.buffer != NULL:
        return self.icon.image.w, self.icon.image.h

      return 0, 0

    void redraw():
      if self.icon.data == NULL || self.icon.image.buffer == NULL:
        return

      fb->draw_bitmap(self.icon.image, x, y)

