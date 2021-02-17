#include "../build/rmkit.h"
#include "../shared/string.h"

class DragHandle: public ui::Widget:
  public:
  int shape = 0
  DragHandle(int x, int y, int w, int h): ui::Widget(x, y, w, h) {}

  void set_shape(int s):
    shape = s

  void render():
    if shape == 0:
      r := min(w/2, h/2)
      fb->draw_circle(x+r, y+r, r, 5, GRAY, true)
    else:
      for i := 0; i < 5; i++:
        fb->draw_rect(x+i, y+i, w-i*2, h-i*2, GRAY, false)

class Shape: public ui::Widget:
  public:
  enum SHAPE { LINE=0, SQUARE, CIRCLE }
  int shape = LINE
  static vector<Shape*> shapes

  DragHandle *handle_one, *handle_two
  Shape(int x, y, w, h, ui::Scene scene, SHAPE sh) : ui::Widget(x, y, w, h):
    scene->add(self)
    shapes.push_back(self)

    shape = sh
    sz := 25
    handle_one = new DragHandle(x, y, sz, sz)
    handle_two = new DragHandle(x+w, y+h, sz, sz)
    handle_two->set_shape(1)

    style := ui::Stylesheet() \
      .valign(ui::Style::VALIGN::MIDDLE) \
      .justify(ui::Style::JUSTIFY::CENTER)

    handle_one->set_style(style.font_size(50))
    handle_two->set_style(style.font_size(50))

    scene->add(handle_one)
    scene->add(handle_two)

    handle_one->mouse.move += PLS_LAMBDA(auto &ev) {
      if not handle_one->mouse_down:
        return

      ev.stop_propagation()

      ox := handle_one->x
      oy := handle_one->y

      handle_one->x = ev.x - handle_one->w/2
      handle_one->y = ev.y - handle_one->h/2

      dx := handle_one->x - ox
      dy := handle_one->y - oy

      handle_two->x += dx
      handle_two->y += dy

      draw_pixel(handle_one)
    }

    handle_two->mouse.move += PLS_LAMBDA(auto &ev) {
      if handle_one->mouse_down:
        return

      ev.stop_propagation()

      handle_two->x = ev.x - handle_two->w/2
      handle_two->y = ev.y - handle_two->h/2
      draw_pixel(handle_two)
    }

    handle_one->mouse.up += PLS_DELEGATE(self.redraw)
    handle_two->mouse.up += PLS_DELEGATE(self.redraw)
    handle_one->mouse.leave += PLS_DELEGATE(self.redraw)
    handle_two->mouse.leave += PLS_DELEGATE(self.redraw)

  void redraw(input::SynMotionEvent &ev):
    redraw()

  void redraw(bool skip_shape=false):
    ui::MainLoop::full_refresh()

  void draw_pixel(ui::Widget *w1):
    fb->draw_line(w1->x+w1->w/2-1, w1->y+w1->h/2-1, w1->x+w1->w/2+1, w1->y+w1->h/2+1, 3, color::GRAY_9)

  string to_lamp():
    &w1 := handle_one
    &w2 := handle_two

    x1 := w1->x + w1->w/2
    y1 := w1->y + w1->h/2
    x2 := w2->x + w2->w/2
    y2 := w2->y + w2->h/2

    w := abs(x2 - x1)
    h := abs(y2 - y1)

    r := int(sqrt(w * w + h * h))

    if shape == LINE:
      return "pen line " + str_utils::join(%{
        to_string(x1),
        to_string(y1),
        to_string(x2),
        to_string(y2)}, ' ')

    if shape == SQUARE:
      return "fastpen rectangle " + str_utils::join(%{
        to_string(x1),
        to_string(y1),
        to_string(x2),
        to_string(y2)}, ' ')

    if shape == CIRCLE:
      return "fastpen circle " + str_utils::join(%{
        to_string(x1),
        to_string(y1),
        to_string(r),
        to_string(0)}, ' ')

    return ""

  void render():
    w1 := handle_one
    w2 := handle_two
    color := color::GRAY_8

    handle_one->render()
    handle_two->render()

    x1 := w1->x + w1->w/2
    y1 := w1->y + w1->h/2
    x2 := w2->x + w2->w/2
    y2 := w2->y + w2->h/2

    w := x2 - x1
    h := y2 - y1

    r := int(sqrt(w * w + h * h))

    if shape == LINE:
      if color != -1:
        fb->draw_line(x1, y1, x2, y2, 3, color)
    else if shape == SQUARE:
      a1 := min(x1, x2)
      b1 := min(y1, y2)
      for i := 0; i < 3; i++:
        fb->draw_rect(a1+i, b1+i, abs(w)-i*2, abs(h)-i*2, color, /* fill */ false)
    else if shape == CIRCLE:
      fb->draw_circle(x1, y1, r, 3, color, /* fill */ false)

vector<Shape*> Shape::shapes = {}

