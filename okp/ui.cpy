#include "defines.h"

import fb
import events

class Widget:
  public:
  int x, y, w, h, dirty, mouse_x, mouse_y
  bool mouse_down, mouse_inside
  static vector<Widget*> widgets

  Widget(int a,b,c,d):
    x = a; y = b; w = c; h = d;
    printf("MAKING WIDGET %lx\n", (uint64_t) this)

    mouse_inside = false
    mouse_down = false

    dirty = 1

  ~Widget(): // can't de-allocate widgets yet
    printf("DESTROYING WIDGET %lx\n", (uint64_t) this)
    for auto it = widgets.begin(); it != widgets.end(); it++:
      if *it == this:
        widgets.erase(it)
        break

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

  virtual void on_mouse_hover(SynEvent ev):
    printf("ON MOUSE HOVER %lx\n", (uint64_t) this)

  static void main(FB &fb):
    for auto &widget: widgets:
      if widget->dirty:
        widget->redraw(fb)
        widget->dirty = 0

  static void mark_widgets(int o_x, o_y):
    for auto widget: widgets:
      widget->maybe_mark_dirty(o_x, o_y)

  static void add(Widget *w):
    widgets.push_back(w)

  // iterate over all widgets and dispatch mouse events
  // TODO: refactor this into cleaner code
  static bool handle_mouse_event(FB &fb, SynEvent ev):
    bool is_hit = false
    bool hit_widget = false

    for auto widget: widgets:
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
        widget->redraw(fb)
      else:
        // mouse leave event
        if prev_mouse_inside:
          widget->on_mouse_leave(ev)
          widget->redraw(fb)

    return hit_widget

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

vector<Widget*> Widget::widgets = vector<Widget*>();

class Text: public Widget:
  public:
  string text

  Text(int x, y, w, h, string t): Widget(x, y, w, h):
    self.text = t

  void redraw(FB &fb):
    freetype::image_data image;
    image.buffer = (uint32_t*) malloc(sizeof(uint32_t)*self.w*self.h)
    memset(image.buffer, WHITE, sizeof(uint32_t)*self.w*self.h)
    image.w = self.w
    image.h = self.h
    fb.draw_text(self.text, self.x, self.y, image)
    free(image.buffer)


class Button: public Widget:
  public:
  string text
  Text *textWidget

  Button(int x, y, w, h, string t): Widget(x,y,w,h):
    self.text = t
    self.textWidget = new Text(x, y, w, h, t)

  ~Button():
    delete self.textWidget

  void redraw(FB &fb):
    self.textWidget->set_coords(x, y, w, h)
    self.textWidget->redraw(fb)

    color = WHITE
    if self.mouse_inside:
      color = BLACK
    fill = false
    if self.mouse_down:
      fill = true
    fb.draw_rect(self.x, self.y, self.w, self.h, color, fill)

class Canvas: public Widget:
  public:
  int mx, my
  uint32_t *mem
  vector<SynEvent> events;

  Canvas(int x, y, w, h): Widget(x,y,w,h):
    this->mem = (uint32_t*) malloc(sizeof(uint32_t) * w * h)

  ~Canvas():
    if this->mem != NULL:
      free(this->mem)
    this->mem = NULL


  void on_mouse_hover(SynEvent ev):
    events.push_back(ev)

  void on_mouse_move(SynEvent ev):
    events.push_back(ev)

  void redraw(FB &fb):
    while events.size():
      ev = *events.rbegin(); events.pop_back();
      fb.draw_rect(ev.x, ev.y, 2, 2, BLACK)
