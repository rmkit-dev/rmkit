#include "../fb/fb.h"

namespace ui:
  class Widget:
    public:
    static framebuffer::FB *fb
    vector<shared_ptr<Widget>> children

    int x, y, w, h
    int mouse_down, mouse_inside, mouse_x, mouse_y
    int dirty
    bool visible

    Widget(int x,y,w,h): x(x), y(y), w(w), h(h):
      printf("MAKING WIDGET %lx\n", (uint64_t) this)

      mouse_inside = false
      mouse_down = false
      visible = true

      dirty = 1

    virtual void redraw():
      pass

    virtual void hide():
      visible = false

    virtual void show():
      visible = true

    // {{{ SIGNAL HANDLERS
    virtual bool ignore_event(input::SynEvent &ev):
      return false

    virtual void on_mouse_enter(input::SynEvent &ev):
      pass

    virtual void on_mouse_leave(input::SynEvent &ev):
      pass

    virtual void on_mouse_click(input::SynEvent &ev):
      pass

    virtual void on_mouse_down(input::SynEvent &ev):
      pass

    virtual void on_mouse_up(input::SynEvent &ev):
      pass

    virtual void on_mouse_move(input::SynEvent &ev):
      pass

    virtual void on_mouse_hover(input::SynEvent &ev):
      pass
    // }}}

    // checks if this widget is hit by a button press
    bool is_hit(int o_x, o_y):
      if o_x < x || o_y < y || o_x > x+w || o_y > y+h:
        return false

      return true

    bool maybe_mark_dirty(int o_x, o_y):
      if self.dirty:
        return false

      if is_hit(o_x, o_y):
        printf("WIDGET IS DIRTY %lx\n", (uint64_t) this)
        dirty = 1
        return true
      return false

    void set_coords(int a=-1, b=-1, c=-1, d=-1):
      if a != -1:
        self.x = a
      if b != -1:
        self.y = b
      if c != -1:
        self.w = c
      if d != -1:
        self.h = d

  framebuffer::FB* Widget::fb = NULL
