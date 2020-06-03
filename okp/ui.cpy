#include "defines.h"

import fb
import events

class Widget:
  public:
  int x, y, w, h, dirty
  static vector<Widget*> widgets

  Widget(int a,b,c,d): 
    x = a; y = b; w = c; h = d;
    printf("MAKING WIDGET %lx\n", (uint64_t) this)

    widgets.push_back(this)
    dirty = 1

  ~Widget(): // can't de-allocate widgets yet
    printf("DESTROYING WIDGET %lx\n", (uint64_t) this)

  virtual void redraw(FB fb):
    printf("REDRAWING WIDGET\n")
    pass

  static void main(FB fb):
    for auto widget: widgets:
      if widget->dirty:
        widget->redraw(fb)
        widget->dirty = 0
    fb.redraw_screen()

  static void mark_widgets(int o_x, o_y):
    for auto widget: widgets:
      widget->maybe_mark_dirty(o_x, o_y)

  static bool handle_click(int o_x, o_y):
    for auto widget: widgets:
      if widget->is_hit(o_x, o_y):
        printf("WIDGET WAS CLICKED %lx\n", (uint64_t) widget)
        widget->run()
        return true
    return false

  void run():
    pass

  // checks if this widget is hit by a button press
  bool is_hit(int o_x, o_y):
    if o_x < x || o_y < y || o_x > x+w || o_y > y+h:
      return false

    printf("WIDGET IS HIT\n")
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
  Button(int x, y, w, h, string text): Widget(x,y,w,h):
    pass

  void redraw(FB fb):
    printf("REDRAWING BUTTON\n")
    fb.draw_rect(self.x, self.y, self.w, self.h, BLACK, false)
