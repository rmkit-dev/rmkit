#include "base.h"
#include "pixmap.h"
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
    icons::Icon icon = {NULL, 0}
    shared_ptr<Pixmap> iconWidget


    Button(int x, y, w, h, string t): Widget(x,y,w,h):
      self.key = Button::key_ctr
      Button::key_ctr++
      self.text = t
      self.textWidget = make_shared<Text>(x, y, w, h, t)
      self.set_justification(ui::Text::JUSTIFY::CENTER)
      #ifdef DEV
      print self.text, "=", input::get_key_str(self.key)
      #endif
      return

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

    void before_redraw():
      has_icon = false
      has_text = false
      if self.icon.data != NULL:
        self.iconWidget = make_shared<Pixmap>(0, 0, ICON_WIDTH, TOOLBAR_HEIGHT, icon)
        has_icon = true
      if self.textWidget != nullptr:
        self.textWidget->restore_coords()
        self.textWidget->text = text
        if text != "":
          has_text = true

      if has_icon && has_text:
        self.iconWidget->x = self.x + x_padding
        self.iconWidget->y = self.y + y_padding
        self.textWidget->x = self.x + self.iconWidget->w
        self.textWidget->y = self.y + y_padding
      else if has_icon:
        rw, rh = self.iconWidget->get_render_size()
        padding = self.w - rw
        if padding > 0:
          padding /= 2
        else:
          padding = 0
        self.iconWidget->x = self.x + x_padding + padding
        self.iconWidget->y = self.y + y_padding
      else if has_text:
        self.textWidget->x = self.x + x_padding
        self.textWidget->y = self.y + y_padding


    void redraw():

      fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

      if self.iconWidget.get() != nullptr:
        self.iconWidget->redraw()

      self.textWidget->redraw()

      color = WHITE
      if self.mouse_inside:
        color = BLACK
      fill = false
      if self.mouse_down:
        fill = true
      fb->draw_rect(self.x, self.y, self.w, self.h, color, fill)

  int Button::key_ctr = 16 // "q"
