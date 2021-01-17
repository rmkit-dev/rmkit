#include "widget.h"
#include "pixmap.h"
#include "text.h"
#include "../input/keycodes.h"

namespace ui:
  // class: ui::Button
  // --- Prototype ---
  // class ui::Button: public ui::Widget
  // -----------------
  // This is a typical button. It optionally supports setting
  // an ICON for the start of the button.
  class Button: public Widget
    public:
    string text
    int x_padding = 0
    int y_padding = 10
    bool underline = false
    shared_ptr<Text> textWidget
    int key
    static int key_ctr

    // variable: icon
    icons::Icon icon = {NULL, 0}
    shared_ptr<Pixmap> iconWidget


    // function: Button
    //
    // Parameters:
    // x - x coordinate of top left corner of button
    // y - y coordinate of top left corner of button
    // w - the width of the button
    // h - the height of the button
    // t - the text label for the button
    Button(int x, y, w, h, string t): Widget(x,y,w,h):
      self.key = Button::key_ctr
      Button::key_ctr++
      self.text = t
      self.textWidget = make_shared<Text>(x, y, w, h, t)
      self.set_justification(ui::TextStyle::JUSTIFY::CENTER)
      #ifdef DEV
      debug self.text, "=", input::get_key_str(self.key)
      #endif
      return

    void on_mouse_move(input::SynMotionEvent &ev):
      ev.stop_propagation()

    void on_mouse_down(input::SynMotionEvent &ev):
      ev.stop_propagation()
      self.dirty = 1

    void on_mouse_up(input::SynMotionEvent &ev):
      self.dirty = 1

    void on_mouse_leave(input::SynMotionEvent &ev):
      self.dirty = 1

    void on_mouse_enter(input::SynMotionEvent &ev):
      self.dirty = 1

    void on_key_pressed(input::SynKeyEvent &ev):
      if ev.key == key && ev.is_pressed:
        input::SynMotionEvent fake
        self.on_mouse_click(fake)

    // function: set_justification
    //
    //      sets the alignment of the text of the button. j is one of ::LEFT,
    //      ::CENTER or ::RIGHT
    void set_justification(TextStyle::JUSTIFY j):
      self.textWidget->style.justify = j

    void before_render():
      has_icon := false
      has_text := false
      if self.icon.data != NULL:
        self.iconWidget = make_shared<Pixmap>(0, 0, 20, 20, icon)
        has_icon = true
      if self.textWidget != nullptr:
        self.textWidget->restore_coords()
        self.textWidget->text = text
        if text != "":
          has_text = true

      if has_icon && has_text:
        self.iconWidget->x = self.x + x_padding
        self.iconWidget->y = self.y + y_padding + 5
        self.textWidget->x = self.x + self.iconWidget->w + 20
        self.textWidget->y = self.y + y_padding
      else if has_icon:
        rw, rh = self.iconWidget->get_render_size()
        padding := self.w - rw
        if padding > 0:
          padding /= 2
        else:
          padding = 0
        self.iconWidget->x = self.x + x_padding + padding
        self.iconWidget->y = self.y + y_padding
      else if has_text:
        self.textWidget->x = self.x + x_padding
        self.textWidget->y = self.y + y_padding


    void render():

      fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

      if self.iconWidget.get() != nullptr:
        self.iconWidget->render()

      self.textWidget->underline = self.underline
      self.textWidget->render()

      color := WHITE
      if self.mouse_inside:
        color = BLACK
      fill := false
      if self.mouse_down:
        fill = true
      fb->draw_rect(self.x, self.y, self.w, self.h, color, fill)

  int Button::key_ctr = 16 // "q"
