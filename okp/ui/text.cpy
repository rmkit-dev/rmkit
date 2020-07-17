#include "base.h"
#include "../defines.h"
#include "../fb/stb_text.h"

namespace ui:
  class Text: public Widget:
    public:
    enum JUSTIFY { LEFT, CENTER, RIGHT }
    string text
    JUSTIFY justify = JUSTIFY::CENTER

    Text(int x, y, w, h, string t): Widget(x, y, w, h):
      self.text = t

    tuple<int, int> get_render_size():
      image = stbtext::get_text_size(self.text.c_str())
      return image.w, image.h
    // TODO: cache the image buffer
    void redraw():
      image = stbtext::get_text_size(self.text.c_str())

      image.buffer = (uint32_t*) malloc(sizeof(uint32_t) * image.w * image.h)
      memset(image.buffer, WHITE, sizeof(uint32_t) * image.w * image.h)

      leftover_x = self.w - image.w
      padding_x = 0

      switch self.justify:
        case JUSTIFY::LEFT:
          break
        case JUSTIFY::CENTER:
          if leftover_x > 0:
            padding_x = leftover_x / 2
          break
        case JUSTIFY::RIGHT:
          if leftover_x > 0:
            padding_x = leftover_x
          break

      fb->draw_text(self.text, self.x + padding_x, self.y, image)

      free(image.buffer)

  class MultiText: public Text:
    public:
    MultiText(int x, y, w, h, string t): Text(x, y, w, h, t):
      pass

    void redraw():
      cur_x = 0
      cur_y = 0
      lines = split(self.text, '\n')
      for auto line: lines:
        cur_x = 0
        tokens = split(line, ' ')
        int max_h = 0
        for auto w: tokens:
          w += " "
          image = stbtext::get_text_size(w.c_str())
          image.buffer = (uint32_t*) malloc(sizeof(uint32_t) * image.w * image.h)
          max_h = max(image.h, max_h)
          memset(image.buffer, WHITE, sizeof(uint32_t) * image.w * image.h)
          if cur_x + image.w + 10 >= self.w:
            cur_x = 0
            cur_y += max_h
          self.fb->draw_text(w, self.x + cur_x, self.y + cur_y, image)
          free(image.buffer)
          cur_x += image.w
        cur_y += max_h
