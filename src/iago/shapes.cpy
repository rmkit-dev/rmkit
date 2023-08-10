// @nosplit
#include <cmath>
#include "../shared/string.h"

// display height from 261.62mm diagonal (10.3 inch) and 4:3 ratio,
// seems to be quite accurate...
const double MILLIMETER = 1872/209.296

namespace shape:
  class DragHandle: public ui::Widget:
    public:
    int shape = 0
    DragHandle(int x, int y, int w, int h): ui::Widget(x, y, w, h) {}

    void set_shape(int s):
      shape = s

    bool ignore_event(input::SynMotionEvent &syn_ev):
      return input::is_touch_event(syn_ev)


    void render():
      if shape == 0:
        r := min(w/2, h/2)
        fb->draw_circle(x+r, y+r, r, 5, GRAY, true)
      else:
        for i := 0; i < 5; i++:
          fb->draw_rect(x+i, y+i, w-i*2, h-i*2, GRAY, false)


  class Shape;
  vector<Shape*> to_draw = {}

  class Shape: public ui::Widget:
    private:
    static double snapping
    tuple<int, int> last_move_snap = tuple<int, int>(0, 0)

    public:
    string name;
    DragHandle *handle_one, *handle_two
    static bool snap_enabled
    static bool rows_header_enabled
    static bool columns_header_enabled
    static int rows 
    static int columns

    static void set_snapping(int mm):
      Shape::snapping = MILLIMETER * mm
      debug "SET SNAPPING TO", Shape::snapping


    Shape(int x, y, w, h, ui::Scene scene) : ui::Widget(x, y, w, h):
      scene->add(self)
      shape::to_draw.push_back(self)
      self->add_drag_handles(scene)

    Shape() : ui::Widget(x, y, w, h):
      return

    int snap_position(int position):
      return snapping * round(position / snapping)

    void snap_handle(ui::Widget *handle):
      if snap_enabled:
        x, y := get_handle_coords(handle)
        handle->x = snap_position(x) - handle->w/2
        handle->y = snap_position(y) - handle->h/2

    void add_drag_handles(ui::Scene scene):
      sz := 25
      handle_one = new DragHandle(x, y, sz, sz)
      handle_two = new DragHandle(x+w, y+h, sz, sz)
      snap_handle(handle_one)
      snap_handle(handle_two)
      handle_two->set_shape(1)

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

        draw_movement(handle_one)
      }

      handle_two->mouse.move += PLS_LAMBDA(auto &ev) {
        if handle_one->mouse_down:
          return

        ev.stop_propagation()

        handle_two->x = ev.x - handle_two->w/2
        handle_two->y = ev.y - handle_two->h/2
        draw_movement(handle_two)
      }

      handle_one->mouse.up += PLS_LAMBDA(auto &ev) {
        snap_handle(handle_one)
        snap_handle(handle_two)
        self->redraw(ev)
      }

      handle_two->mouse.up += PLS_LAMBDA(auto &ev) {
        snap_handle(handle_two)
        self->redraw(ev)
      }

      handle_one->mouse.leave += PLS_DELEGATE(self.redraw)
      handle_two->mouse.leave += PLS_DELEGATE(self.redraw)

    void redraw(input::SynMotionEvent &ev):
      redraw()

    void redraw(bool skip_shape=false):
      ui::MainLoop::full_refresh()

    void draw_movement(ui::Widget *w1):
      if snap_enabled:
        x, y := get_handle_coords(w1)
        x = snap_position(x)
        y = snap_position(y)
        last_x, last_y := self->last_move_snap
        if x != last_x || y != last_y:
          draw_pixel(last_x, last_y, WHITE)
          draw_pixel(x, y, BLACK)
          last_move_snap = tuple<int, int>(x, y)
      else:
        draw_pixel(w1)

    void draw_pixel(ui::Widget *w1):
      x, y := get_handle_coords(w1)
      draw_pixel(x, y, color::GRAY_9)

    void draw_pixel(int x, int y, int color):
      fb->draw_line(x-1, y-1, x+1, y+1, 3, color)

    tuple<int, int> get_handle_coords(ui::Widget *w1)
      return (w1->x + w1->w/2), (w1->y + w1->h/2)

    virtual string to_lamp():
      return ""

    virtual void render():
      return

  double Shape::snapping = MILLIMETER * 5
  int Shape::rows = 1
  int Shape::columns = 1
  bool Shape::snap_enabled = false
  bool Shape::rows_header_enabled = false
  bool Shape::columns_header_enabled = false

  class Line : public Shape:
    public:
    const string name = "Line"
    Line(int x, y, w, h, ui::Scene scene) : Shape(x, y, w, h, scene):
      handle_two->y = handle_one->y

    void render():
      handle_one->render()
      handle_two->render()

      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(handle_two)

      w := x2 - x1
      h := y2 - y1

      r := int(sqrt(w * w + h * h))

      fb->draw_line(x1, y1, x2, y2, 3, color::GRAY_8)

    string to_lamp():
      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(handle_two)

      return "pen line " + str_utils::join(%{
        to_string(x1),
        to_string(y1),
        to_string(x2),
        to_string(y2)}, ' ')

  class HLine: Line:
    public:
    HLine(int x, y, w, h, ui::Scene scene) : Line(x, y, w, h, scene):
      handle_two->x = handle_one->x + w

    void before_render():
      handle_one->y = handle_two->y

  class VLine: Line:
    public:
    VLine(int x, y, w, h, ui::Scene scene) : Line(x, y, w, h, scene):
      handle_two->y = handle_one->y + h

    void before_render():
      handle_one->x = handle_two->x

  class Circle : public Shape:
    public:
    const string name = "Circle"
    Circle(int x, y, w, h, ui::Scene scene) : Shape(x, y, w, h, scene):
      return

    void render():
      handle_one->render()
      handle_two->render()

      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(handle_two)

      w := x2 - x1
      h := y2 - y1

      r := int(sqrt(w * w + h * h))

      fb->draw_circle(x1, y1, r, 3, color::GRAY_8, /* fill */ false)

    string to_lamp():
      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(handle_two)

      w := abs(x2 - x1)
      h := abs(y2 - y1)

      r := int(sqrt(w * w + h * h))

      return "pen circle " + str_utils::join(%{
        to_string(x1),
        to_string(y1),
        to_string(r),
        to_string(r)}, ' ')

  class Rectangle : public Shape:
    public:
    const string name = "Rectangle"
    Rectangle(int x, y, w, h, ui::Scene scene) : Shape(x, y, w, h, scene):
      return

    void render():
      handle_one->render()
      handle_two->render()

      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(handle_two)

      w := x2 - x1
      h := y2 - y1

      a1 := min(x1, x2)
      b1 := min(y1, y2)

      for i := 0; i < 3; i++:
        fb->draw_rect(a1+i, b1+i, abs(w)-i*2, abs(h)-i*2, color::GRAY_8, /* fill */ false)

    string to_lamp():
      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(handle_two)

      return "pen rectangle " + str_utils::join(%{
        to_string(x1),
        to_string(y1),
        to_string(x2),
        to_string(y2)}, ' ')

  class Table : public Shape:
    public:
    std::string a

    const string name = "Table"
    Table(int x, y, w, h, ui::Scene scene) : Shape(x, y, w, h, scene):
      return

    void render():
      handle_one->render()
      handle_two->render()

      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(handle_two)

      w := x2 - x1
      h := y2 - y1
      r := rows
      c := columns
      rh := h/rows
      cw := w/columns

      rhw := 0
      chh := 0
      
      a1 := min(x1, x2)
      b1 := min(y1, y2)

      for i := 0; i < 3; i++:
        if rows_header_enabled:
          rhw = cw/2          
        if columns_header_enabled:
          chh = rh/2
        if columns_header_enabled:
          fb->draw_line(x1-rhw, y1-rh/2, x2, y1-rh/2, 3, color::GRAY_8)
        for n := 0; n <= rows; n++:
          fb->draw_line(x1-rhw, y1+rh*n, x2, y1+rh*n, 3, color::GRAY_8)        
        if rows_header_enabled:
          fb->draw_line(x1-cw/2, y1-chh, x1-cw/2, y2, 3, color::GRAY_8)
        for n := 0; n <= columns; n++:
          fb->draw_line(x1+cw*n, y1-chh, x1+cw*n, y2, 3, color::GRAY_8)

    string to_lamp():
      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(handle_two)
      r := rows
      c := columns
      w := x2 - x1
      h := y2 - y1
      rh := h/rows
      cw := w/columns
      
      rhw := 0
      chh := 0

      if rows_header_enabled:
        rhw = cw/2          
      if columns_header_enabled:
        chh = rh/2
      if columns_header_enabled:
      
      if columns_header_enabled:
        b := "pen line " + str_utils::join(%{
        to_string(x1-rhw),
        to_string(y1-rh/2),
        to_string(x2),
        to_string(y1-rh/2),
        "\n"}, ' ')
        a += b
      for n :=0; n <= rows; n++:      
        b := "pen line " + str_utils::join(%{
        to_string(x1-rhw),
        to_string(y1+rh*n),
        to_string(x2),
        to_string(y1+rh*n),
        "\n"}, ' ')
        a += b
      if rows_header_enabled:
        b := "pen line " + str_utils::join(%{
        to_string(x1-cw/2),
        to_string(y1-chh),
        to_string(x1-cw/2),
        to_string(y2),
        "\n"}, ' ')
        a += b
      for n :=0; n <= columns; n++:
        b := "pen line " + str_utils::join(%{
        to_string(x1+cw*n),
        to_string(y1-chh),
        to_string(x1+cw*n),
        to_string(y2),
        "\n"}, ' ')
        a += b
      return a

  class Bezier : public Shape:
    public:
    bool is_attached = false
    DragHandle *control_one, *control_two
    Bezier(int x, y, w, h, ui::Scene scene): Shape():
      name = "Bezier"
      scene->add(self)

      control_one_x := x+w/4
      control_one_y := y-h

      if to_draw.size() > 0:
        last_shape := to_draw.back()
        if last_shape->name == "Bezier":
          obj := (Bezier *)last_shape
          x = obj->handle_two->x
          y = obj->handle_two->y
          // Mirror control two of last shape
          control_one_x = 2*x-obj->control_two->x
          control_one_y = 2*y-obj->control_two->y
          obj->is_attached = true
          is_attached = true

      if x+w > fb->display_width:
        w = fb->display_width-x-10

      sz := 25
      handle_one = new DragHandle(x, y, sz, sz)
      handle_two = new DragHandle(x+w, y, sz, sz)
      control_one = new DragHandle(control_one_x, control_one_y, sz, sz)
      control_two = new DragHandle(x+w-w/4, y+h, sz, sz)

      shape::to_draw.push_back(self)

      handle_one->set_shape(1)
      handle_two->set_shape(1)

      scene->add(handle_one)
      scene->add(handle_two)
      scene->add(control_one)
      scene->add(control_two)

      handle_one->mouse.move += PLS_LAMBDA(auto &ev) {
        if not handle_one->mouse_down:
          return

        if !is_attached:
          ev.stop_propagation()

        ox := handle_one->x
        oy := handle_one->y

        handle_one->x = ev.x - handle_one->w/2
        handle_one->y = ev.y - handle_one->h/2

        dx := handle_one->x - ox
        dy := handle_one->y - oy
        control_one->x += dx
        control_one->y += dy
        draw_pixel(handle_one)
      }

      handle_two->mouse.move += PLS_LAMBDA(auto &ev) {
        if handle_one->mouse_down:
          return

        ev.stop_propagation()

        ox := handle_two->x
        oy := handle_two->y

        handle_two->x = ev.x - handle_two->w/2
        handle_two->y = ev.y - handle_two->h/2

        dx := handle_two->x - ox
        dy := handle_two->y - oy
        control_two->x += dx
        control_two->y += dy
        draw_pixel(handle_two)
      }

      control_one->mouse.move += PLS_LAMBDA(auto &ev) {
        if not control_one->mouse_down:
          return

        ev.stop_propagation()
        control_one->x = ev.x - control_one->w/2
        control_one->y = ev.y - control_one->h/2
        draw_pixel(control_one)
      }

      control_two->mouse.move += PLS_LAMBDA(auto &ev) {
        if control_one->mouse_down:
          return

        ev.stop_propagation()

        control_two->x = ev.x - control_two->w/2
        control_two->y = ev.y - control_two->h/2
        draw_pixel(control_two)
      }

      handle_one->mouse.up += PLS_DELEGATE(self.redraw)
      handle_two->mouse.up += PLS_DELEGATE(self.redraw)
      control_one->mouse.up += PLS_DELEGATE(self.redraw)
      control_two->mouse.up += PLS_DELEGATE(self.redraw)
      handle_one->mouse.leave += PLS_DELEGATE(self.redraw)
      handle_two->mouse.leave += PLS_DELEGATE(self.redraw)
      control_one->mouse.leave += PLS_DELEGATE(self.redraw)
      control_two->mouse.leave += PLS_DELEGATE(self.redraw)

    void render():
      handle_one->render()
      handle_two->render()
      control_one->render()
      control_two->render()

      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(control_one)
      x3, y3 := get_handle_coords(control_two)
      x4, y4 := get_handle_coords(handle_two)

      fb->draw_bezier(x1, y1, x2, y2, x3, y3, x4, y4, 3, color::GRAY_8)
      fb->draw_line(x1, y1, x2, y2, 3, color::GRAY_8)
      fb->draw_line(x3, y3, x4, y4, 3, color::GRAY_8)

    string to_lamp():
      x1, y1 := get_handle_coords(handle_one)
      x2, y2 := get_handle_coords(control_one)
      x3, y3 := get_handle_coords(control_two)
      x4, y4 := get_handle_coords(handle_two)

      return "pen bezier " + str_utils::join(%{
        to_string(x1),
        to_string(y1),
        to_string(x2),
        to_string(y2),
        to_string(x3),
        to_string(y3),
        to_string(x4),
        to_string(y4)}, ' ')
