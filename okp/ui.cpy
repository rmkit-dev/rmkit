#include "defines.h"

#include "fb.h"
#include "input.h"

class Widget:
  public:
  int x, y, w, h, dirty, mouse_x, mouse_y
  bool mouse_down, mouse_inside
  static vector<shared_ptr<Widget>> widgets
  static FB *fb

  Widget(int a,b,c,d):
    x = a; y = b; w = c; h = d;
    printf("MAKING WIDGET %lx\n", (uint64_t) this)

    mouse_inside = false
    mouse_down = false

    dirty = 1

  ~Widget(): // can't de-allocate widgets yet
    printf("DESTROYING WIDGET %lx\n", (uint64_t) this)
    for auto it = widgets.begin(); it != widgets.end(); it++:
      if it->get() == this:
        widgets.erase(it)
        break

  virtual void redraw(FB &fb):
    pass

  virtual bool ignore_event(SynEvent &ev):
    pass

  virtual void on_mouse_enter(SynEvent &ev):
    pass

  virtual void on_mouse_leave(SynEvent &ev):
    pass

  virtual void on_mouse_click(SynEvent &ev):
    pass

  virtual void on_mouse_down(SynEvent &ev):
    pass

  virtual void on_mouse_up(SynEvent &ev):
    pass

  virtual void on_mouse_move(SynEvent &ev):
    pass

  virtual void on_mouse_hover(SynEvent &ev):
    pass

  static void main(FB &fb):
    for auto &widget: widgets:
      if widget->dirty:
        widget->redraw(fb)
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
  static bool handle_motion_event(SynEvent &ev):
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

vector<shared_ptr<Widget>> Widget::widgets = vector<shared_ptr<Widget>>();
FB* Widget::fb = NULL

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
  shared_ptr<Text> textWidget

  Button(int x, y, w, h, string t): Widget(x,y,w,h):
    self.text = t
    self.textWidget = shared_ptr<Text>(new Text(x, y, w, h, t))

  void on_mouse_down(SynEvent &ev):
    self.dirty = 1

  void on_mouse_up(SynEvent &ev):
    self.dirty = 1

  void on_mouse_leave(SynEvent &ev):
    self.dirty = 1

  void on_mouse_enter(SynEvent &ev):
    self.dirty = 1

  void redraw(FB &fb):
    self.textWidget->text = text
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
  remarkable_color *mem
  vector<SynEvent> events;
  vector<remarkable_color*> undo_stack;
  vector<remarkable_color*> redo_stack;
  SynEvent last_ev

  Canvas(int x, y, w, h): Widget(x,y,w,h):
    this->mem = (remarkable_color*) malloc(sizeof(remarkable_color) * w * h)
    remarkable_color* fbcopy = (remarkable_color*) malloc(self.fb->byte_size)
    memcpy(fbcopy, self.fb->fbmem, self.fb->byte_size)
    self.undo_stack.push_back(fbcopy)

  ~Canvas():
    if this->mem != NULL:
      free(this->mem)
    this->mem = NULL

  bool ignore_event(SynEvent &ev):
    return Input::is_touch_event(ev) != NULL

  void on_mouse_move(SynEvent &ev):
    events.push_back(ev)
    self.redraw(*self.fb)

  void on_mouse_up(SynEvent &ev):
    #ifdef DEV
    push_undo()
    #endif

    SynEvent null_ev
    null_ev.original = NULL
    self.events.push_back(null_ev)

  void on_mouse_hover(SynEvent &ev):
    pass

  void redraw(FB &fb):
    stroke = 4
    for auto ev: self.events:
      if ev.original != NULL:
        if last_ev.original != NULL:
          fb.draw_line(last_ev.x, last_ev.y, ev.x,ev.y, stroke, BLACK)
        else:
          fb.draw_rect(ev.x, ev.y, stroke, stroke, BLACK)
      last_ev = ev
    self.events.clear()

  void push_undo():
    printf("ADDING TO UNDO STACK\n")
    remarkable_color* fbcopy = (remarkable_color*) malloc(self.fb->byte_size)
    memcpy(fbcopy, self.fb->fbmem, self.fb->byte_size)
    self.undo_stack.push_back(fbcopy)

  void undo():
    if self.undo_stack.size() > 1:
      // put last fb from undo stack into fb
      self.redo_stack.push_back(self.undo_stack.back())
      self.undo_stack.pop_back()
      remarkable_color* undofb = self.undo_stack.back()
      memcpy(self.fb->fbmem, undofb, self.fb->byte_size)
      Widget::refresh()

  void redo():
    if self.redo_stack.size() > 0:
      remarkable_color* redofb = self.redo_stack.back()
      self.redo_stack.pop_back()
      memcpy(self.fb->fbmem, redofb, self.fb->byte_size)
      self.undo_stack.push_back(redofb)
      Widget::refresh()
