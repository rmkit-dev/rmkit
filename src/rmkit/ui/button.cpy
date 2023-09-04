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
    static Stylesheet DEFAULT_STYLE = {}
    string text
    int x_padding = 0
    int y_padding = 10
    shared_ptr<Text> textWidget
    int key
    static int key_ctr = 16 // "q"

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
      #ifdef DEV
      debug self.text, "=", input::get_key_str(self.key)
      #endif
      self.set_style(DEFAULT_STYLE)
      return

    void set_style(const Stylesheet & style):
      Widget::set_style(style)
      self.textWidget->set_style(self.style.inherit().text_style().alignment())

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

      if style.valign != Style::VALIGN::TOP:
        y_padding = 0

      draw_y := 0
      if has_icon:
        switch self.style.valign:
          case Style::VALIGN::MIDDLE:
            draw_y += (self.h - iconWidget->h) / 2
            break
          case Style::VALIGN::BOTTOM:
            draw_y += self.h - iconWidget->h
            break

      if has_icon && has_text:
        self.iconWidget->x = self.x + x_padding
        self.iconWidget->y = self.y + y_padding + 5 + draw_y
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
        self.iconWidget->y = self.y + y_padding + draw_y
      else if has_text:
        self.textWidget->x = self.x + x_padding
        self.textWidget->y = self.y + y_padding


    void render():

      fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

      if self.iconWidget.get() != nullptr:
        self.iconWidget->render()

      self.textWidget->render()

      color := WHITE
      if self.mouse_inside:
        color = BLACK
      fill := false
      if self.mouse_down:
        fill = true
      fb->draw_rect(self.x, self.y, self.w, self.h, color, fill)

  class ToggleButton: public ui::Button:
    public:
    PLS_DEFINE_SIGNAL(TOGGLE_EVENT, int)
    class TOGGLE_EVENTS:
      public:
      TOGGLE_EVENT toggled
    ;
    TOGGLE_EVENTS events

    int toggled = false
    ToggleButton(int x, y, w, h, string t): ui::Button(x,y,w,h,t):
      pass

    void before_render():
      ui::Button::before_render()
      if toggled:
        self.textWidget->text = "[x] " + self.text
      else:
        self.textWidget->text = "[ ] " + self.text

    bool get_value():
      return toggled

    void render():
      ui::Button::render()

    void on_mouse_click(input::SynMotionEvent &ev):
      toggled = !toggled
      self.events.toggled(toggled)
      self.dirty = 1
  ;
