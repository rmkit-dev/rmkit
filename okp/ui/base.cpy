#include "../fb/fb.h"

namespace ui:
  class Widget:
    public:
    static framebuffer::FB *fb
    vector<shared_ptr<Widget>> children

    int x, y, w, h
    int _x, _y, _w, _h // the original values the widget was instantiated with
    int mouse_down = false, mouse_inside = false, mouse_x, mouse_y
    int dirty = 1
    bool visible = true

    Widget(int x,y,w,h): x(x), y(y), w(w), h(h), _x(x), _y(y), _w(w), _h(h):
      pass

    virtual void before_redraw():
      pass

    virtual void redraw():
      pass

    virtual tuple<int, int> get_render_size():
      return self.w, self.h

    virtual void undraw():
      self.fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

    virtual void hide():
      visible = false

    virtual void show():
      visible = true

    virtual void mark_redraw():
      self.dirty = 1

    // {{{ SIGNAL HANDLERS
    virtual bool ignore_event(input::SynMouseEvent &ev):
      return false

    virtual void on_mouse_enter(input::SynMouseEvent &ev):
      pass

    virtual void on_mouse_leave(input::SynMouseEvent &ev):
      pass

    virtual void on_mouse_click(input::SynMouseEvent &ev):
      pass

    virtual void on_mouse_down(input::SynMouseEvent &ev):
      pass

    virtual void on_mouse_up(input::SynMouseEvent &ev):
      pass

    virtual void on_mouse_move(input::SynMouseEvent &ev):
      pass

    virtual void on_mouse_hover(input::SynMouseEvent &ev):
      pass

    virtual void on_key_pressed(input::SynKeyEvent &ev):
      pass
    // }}}

    // checks if this widget is hit by a button press
    bool is_hit(int o_x, o_y):
      if o_x < x || o_y < y || o_x > x+w || o_y > y+h:
        return false

      return true

    void set_coords(int a=-1, b=-1, c=-1, d=-1):
      if a != -1:
        self.x = a
      if b != -1:
        self.y = b
      if c != -1:
        self.w = c
      if d != -1:
        self.h = d

    void restore_coords():
      x = _x
      y = _y
      w = _w
      h = _h

  framebuffer::FB* Widget::fb = NULL
