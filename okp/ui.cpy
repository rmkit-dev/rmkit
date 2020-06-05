#include "defines.h"

import fb
import events

class Widget:
  public:
  int x, y, w, h, dirty
  bool mouse_down, mouse_inside
  static vector<Widget*> widgets

  Widget(int a,b,c,d):
    x = a; y = b; w = c; h = d;
    printf("MAKING WIDGET %lx\n", (uint64_t) this)

    mouse_inside = false
    mouse_down = false

    widgets.push_back(this)
    dirty = 1

  ~Widget(): // can't de-allocate widgets yet
    printf("DESTROYING WIDGET %lx\n", (uint64_t) this)

  virtual void redraw(FB &fb):
    printf("REDRAWING WIDGET\n")

  virtual void on_mouse_enter(SynEvent ev):
    printf("ON MOUSE ENTER %lx\n", (uint64_t) this)

  virtual void on_mouse_leave(SynEvent ev):
    printf("ON MOUSE LEAVE %lx\n", (uint64_t) this)

  virtual void on_mouse_click(SynEvent ev):
    printf("ON MOUSE CLICK %lx\n", (uint64_t) this)

  virtual void on_mouse_down(SynEvent ev):
    printf("ON MOUSE DOWN %lx\n", (uint64_t) this)

  virtual void on_mouse_up(SynEvent ev):
    printf("ON MOUSE UP %lx\n", (uint64_t) this)

  virtual void on_mouse_move(SynEvent ev):
    printf("ON MOUSE MOVE %lx\n", (uint64_t) this)

  static void main(FB &fb):
    for auto &widget: widgets:
      if widget->dirty:
        widget->redraw(fb)
        widget->dirty = 0

  static void mark_widgets(int o_x, o_y):
    for auto widget: widgets:
      widget->maybe_mark_dirty(o_x, o_y)

  static bool handle_mouse(int o_x, o_y):
    pass

  // iterate over all widgets and dispatch mouse events
  static bool handle_mouse_event(SynEvent ev):
    bool is_hit = false
    bool hit_widget = false

    for auto widget: widgets:
      is_hit = widget->is_hit(ev.x, ev.y)
      if widget->mouse_down && !ev.left:
        widget->mouse_down = false
        if is_hit:
          widget->on_mouse_up(ev)
          widget->on_mouse_click(ev)
      if is_hit:
        if !widget->mouse_inside:
          widget->on_mouse_enter(ev)
        if !widget->mouse_down && ev.left:
          widget->on_mouse_down(ev)
        widget->on_mouse_move(ev)
        hit_widget = true
      else:
        if widget->mouse_inside:
          widget->on_mouse_leave(ev)

      widget->mouse_inside = (bool) is_hit
      widget->mouse_down = ev.left

    return hit_widget

  void run():
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

vector<Widget*> Widget::widgets = vector<Widget*>();

class Button: Widget:
  public:
  string text

  Button(int x, y, w, h, string t): Widget(x,y,w,h):
    self.text = t

  def draw_text(FB &fb):
    image_data image;
    image.buffer = (unsigned char*) malloc(sizeof(char)*self.w*self.h)
    memset(image.buffer, 0, sizeof(char)*self.w*self.h)
    image.w = self.w
    image.h = self.h
    fb.draw_text(self.text, self.x, self.y, image)
    free(image.buffer)

  void redraw(FB &fb):
    printf("REDRAWING BUTTON\n")
    fb.draw_rect(self.x, self.y, self.w, self.h, BLACK, false)
    self.draw_text(fb)
