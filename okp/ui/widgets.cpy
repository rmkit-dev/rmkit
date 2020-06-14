#include "base.h"

namespace ui:
  class Text: public Widget:
    public:
    enum JUSTIFY { LEFT, CENTER, RIGHT }
    string text
    JUSTIFY justify = JUSTIFY::CENTER

    Text(int x, y, w, h, string t): Widget(x, y, w, h):
      self.text = t

    // TODO: cache the image buffer
    void redraw():
      freetype::image_data image;
      image.buffer = (uint32_t*) malloc(sizeof(uint32_t)*self.w*self.h)
      memset(image.buffer, WHITE, sizeof(uint32_t)*self.w*self.h)
      image.w = self.w
      image.h = self.h

      switch justify:
        case JUSTIFY::LEFT:
          fb->draw_text(self.text, self.x, self.y, image)
          break
        case JUSTIFY::CENTER:
          fb->draw_text_center(self.text, self.x, self.y, image)
          break
        case JUSTIFY::RIGHT:
          fb->draw_text_right(self.text, self.x, self.y, image)
          break
        default:
          fb->draw_text(self.text, self.x, self.y, image)
      free(image.buffer)


  class Button: public Widget:
    public:
    string text
    shared_ptr<Text> textWidget

    Button(int x, y, w, h, string t): Widget(x,y,w,h):
      self.text = t
      self.textWidget = shared_ptr<Text>(new Text(x, y, w, h, t))

    void on_mouse_down(input::SynEvent &ev):
      self.dirty = 1

    void on_mouse_up(input::SynEvent &ev):
      self.dirty = 1

    void on_mouse_leave(input::SynEvent &ev):
      self.dirty = 1

    void on_mouse_enter(input::SynEvent &ev):
      self.dirty = 1

    void set_justification(Text::JUSTIFY j):
      self.textWidget->justify = j

    void redraw():
      fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)
      self.textWidget->text = text
      self.textWidget->set_coords(x, y, w, h)
      self.textWidget->redraw()

      color = WHITE
      if self.mouse_inside:
        color = BLACK
      fill = false
      if self.mouse_down:
        fill = true
      fb->draw_rect(self.x, self.y, self.w, self.h, color, fill)
