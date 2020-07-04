#include "base.h"
#include "layouts.h"
#include "text.h"

namespace ui:
  class CachedIcon: public icons::Icon:
    public:
    image_data *image = NULL
    static map<string, image_data*> CACHE

    CachedIcon(unsigned char *d, int l):
      self.data = d
      self.len = l
      return

    CachedIcon(unsigned char *d, int l, const char* n):
      self.data = d
      self.len = l
      self.name = n
      self.decode_cached()
      return

    ~CachedIcon():
      if self.name == NULL && self.image != NULL:
        free(self.image->buffer)
        delete self.image


    void decode():
      if self.data == NULL:
        return
      if self.image != NULL:
        return

      unsigned int iconw = 0
      unsigned int iconh = 0
      vector<unsigned char> out
      uint32_t* buf

      lodepng::decode(out, iconw, iconh, self.data, self.len)
      buf = (uint32_t*) malloc(iconw*iconh*sizeof(uint32_t))
      buf = (uint32_t*) memcpy(buf, out.data(), out.size())
      self.image = new image_data{(uint32_t*) buf, (int) iconw, (int) iconh}

    void decode_cached():
      if self.name == NULL:
        self.decode()
        return
      if self.data == NULL:
        return
      if self.image != NULL:
        return

      it = CACHE.find(self.name)
      if it != CACHE.end():
        self.image = it->second
      else:
        self.decode()
        CACHE[self.name] = self.image

  map<string, image_data*> CachedIcon::CACHE = {}


  class Pixmap: public Widget:
    public:
    CachedIcon icon = {NULL, 0}
    Pixmap(int x, y, w, h, icons::Icon ico): Widget(x,y,w,h):
      self.icon = CachedIcon({ico.data, (int) ico.len, ico.name})

    tuple<int, int> get_render_size():
      if self.icon.image != NULL:
        return self.icon.image->w, self.icon.image->h

      return 0, 0

    void redraw():
      if self.icon.image != NULL:
        fb->draw_bitmap(*self.icon.image, x, y)

