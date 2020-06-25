#include "base.h"
#include "text.h"
#include "../input/keycodes.h"

namespace ui:
  class Button: public Widget:
    public:
    string text
    int x_padding = 0
    int y_padding = 10
    shared_ptr<Text> textWidget
    int key
    static int key_ctr
    icons::Icon *icon = NULL

    void set_icon(icons::Icon *icon):
      self.icon = icon

    Button(int x, y, w, h, string t): Widget(x,y,w,h):
      self.key = Button::key_ctr
      Button::key_ctr++
      self.text = t
      self.textWidget = make_shared<Text>(x, y, w, h, t)
      self.set_justification(ui::Text::JUSTIFY::CENTER)
      print self.text, "=", input::get_key_str(self.key)

    void on_mouse_move(input::SynMouseEvent &ev):
      ev.stop_propagation = true

    void on_mouse_down(input::SynMouseEvent &ev):
      ev.stop_propagation = true
      self.dirty = 1

    void on_mouse_up(input::SynMouseEvent &ev):
      self.dirty = 1

    void on_mouse_leave(input::SynMouseEvent &ev):
      self.dirty = 1

    void on_mouse_enter(input::SynMouseEvent &ev):
      self.dirty = 1

    void on_key_pressed(input::SynKeyEvent &ev):
      if ev.key == key && ev.is_pressed:
        input::SynMouseEvent fake
        self.on_mouse_click(fake)

    void set_justification(Text::JUSTIFY j):
      self.textWidget->justify = j

    void redraw():
      fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

      unsigned int iconw = 0
      unsigned int iconh = 0
      if self.icon != NULL:
        vector<unsigned char> out

        lodepng::decode(out, iconw, iconh, self.icon->data, self.icon->len)
        image = freetype::image_data{(uint32_t*) out.data(),iconw,iconh}
        px = 0
        if self.text == "":
          px = 10
        fb->draw_bitmap(image, x+x_padding+px, y+y_padding)

      self.textWidget->text = text
      self.textWidget->set_coords(x+x_padding+iconw+10, y+y_padding, \
        self.w - x_padding-iconw-10, self.h - y_padding)
      self.textWidget->redraw()

      color = WHITE
      if self.mouse_inside:
        color = BLACK
      fill = false
      if self.mouse_down:
        fill = true
      fb->draw_rect(self.x, self.y, self.w, self.h, color, fill)

  int Button::key_ctr = 16 // "q"
