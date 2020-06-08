#include "defines.h"

#include "fb.h"
#include "input.h"

namespace ui:
  class Widget:
    public:
    static framebuffer::FB *fb
    int x, y, w, h
    int mouse_down, mouse_inside, mouse_x, mouse_y
    int dirty

    Widget(int x,y,w,h): x(x), y(y), w(w), h(h):
      printf("MAKING WIDGET %lx\n", (uint64_t) this)

      mouse_inside = false
      mouse_down = false

      dirty = 1

    virtual void redraw():
      pass

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

    // checks if this widget is hit by a button press
    bool is_hit(int o_x, o_y):
      if o_x < x || o_y < y || o_x > x+w || o_y > y+h:
        return false

      return true

    bool maybe_mark_dirty(int o_x, o_y):
      if this->dirty:
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

  class MainLoop:
    public:
    int mouse_x, mouse_y
    bool mouse_down, mouse_inside
    static vector<shared_ptr<Widget>> widgets

    static void main():
      for auto &widget: widgets:
        if widget->dirty:
          widget->redraw()
          widget->dirty = 0

    static void refresh():
      for auto &widget: widgets:
        widget->dirty = 1

    static void mark_widgets(int o_x, o_y):
      for auto widget: widgets:
        widget->maybe_mark_dirty(o_x, o_y)

    static void add(Widget *w):
      widgets.push_back(shared_ptr<Widget>(w))

    // iterate over all widgets and dispatch mouse events
    // TODO: refactor this into cleaner code
    static bool handle_motion_event(input::SynEvent &ev):
      bool is_hit = false
      bool hit_widget = false
      if ev.x == -1 || ev.y == -1:
        return false

      for auto widget: widgets:
        if widget->ignore_event(ev):
          continue

        is_hit = widget->is_hit(ev.x, ev.y)

        prev_mouse_down = widget->mouse_down
        prev_mouse_inside = widget->mouse_inside
        prev_mouse_x = widget->mouse_x
        prev_mouse_y = widget->mouse_y

        widget->mouse_down = ev.left && is_hit
        widget->mouse_inside = is_hit

        if is_hit:
          if widget->mouse_down:
            widget->mouse_x = ev.x
            widget->mouse_y = ev.y
            // mouse move issued on is_hit
            widget->on_mouse_move(ev)
          else:
            // we have mouse_move and mouse_hover
            // hover is for stylus
            widget->on_mouse_hover(ev)


          // mouse down event
          if !prev_mouse_down && ev.left:
            widget->on_mouse_down(ev)

          // mouse up / click events
          if prev_mouse_down && !ev.left::
            widget->on_mouse_up(ev)
            widget->on_mouse_click(ev)

          // mouse enter event
          if !prev_mouse_inside:
            widget->on_mouse_enter(ev)

          hit_widget = true
          break
        else:
          // mouse leave event
          if prev_mouse_inside:
            widget->on_mouse_leave(ev)


      return hit_widget


  vector<shared_ptr<Widget>> MainLoop::widgets = vector<shared_ptr<Widget>>();
  framebuffer::FB* Widget::fb = NULL

