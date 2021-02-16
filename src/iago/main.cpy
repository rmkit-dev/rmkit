#include "../build/rmkit.h"
#include "../shared/string.h"

class AppBackground: public ui::Widget:
  public:
  int byte_size
  framebuffer::VirtualFB *vfb = NULL

  AppBackground(int x, y, w, h): ui::Widget(x, y, w, h):
    self.byte_size = w*h*sizeof(remarkable_color)

    fw, fh := fb->get_display_size()
    vfb = new framebuffer::VirtualFB(fw, fh)
    vfb->clear_screen()
    vfb->fbmem = (remarkable_color*) memcpy(vfb->fbmem, fb->fbmem, self.byte_size)

  void render():
    if rm2fb::IN_RM2FB_SHIM:
      fb->waveform_mode = WAVEFORM_MODE_GC16
    else:
      fb->waveform_mode = WAVEFORM_MODE_AUTO

    memcpy(fb->fbmem, vfb->fbmem, self.byte_size)

    fb->perform_redraw(true)
    fb->dirty = 1

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

class App:
  public:
  AppBackground* app_bg

  shared_ptr<framebuffer::FB> fb
  App():
    fb = framebuffer::get()
    w, h = fb->get_display_size()

    fb->dither = framebuffer::DITHER::BAYER_2
    fb->waveform_mode = WAVEFORM_MODE_DU

    scene := ui::make_scene()
    ui::MainLoop::set_scene(scene)
    app_bg = new AppBackground(0, 0, w, h)
    scene->add(app_bg)

    style := ui::Stylesheet() \
      .valign(ui::Style::VALIGN::MIDDLE) \
      .justify(ui::Style::JUSTIFY::CENTER)

    h_layout := ui::HorizontalLayout(0, h-60, w, 50, scene)


    no_button := new ui::Button(0, 0, 200, 50, "cancel")
    ok_button := new ui::Button(0, 0, 200, 50, "ok")
    h_layout.pack_end(ok_button)
    h_layout.pack_end(no_button)

    shape_dropdown := new ui::TextDropdown(0, 0, 250, 50, "add")
    shape_dropdown->dir = ui::DropdownButton::DIRECTION::UP
    shape_dropdown->add_section("add shape")->add_options({"line", "rect", "circle"})
    h_layout.pack_center(shape_dropdown)

    no_button->set_style(style)
    ok_button->set_style(style)
    no_button->mouse.click += PLS_LAMBDA(auto &ev) {
      self.cleanup()
      exit(0)
    }

    ok_button->mouse.click += PLS_LAMBDA(auto &ev) {
      self.cleanup()
      shape_strs := vector<string>{}
      for auto sh : Shape::shapes:
        str := sh->to_lamp()
        cmd := "echo '"+ str + "' | /opt/bin/lamp"
        debug "RUNNING", cmd
        _ := system("sleep 0.1")
        _ = system(cmd.c_str())
      _ := system("sleep 0.5")
      exit(0)
    }

    shape_dropdown->events.selected += PLS_LAMBDA(int i) {
      val := shape_dropdown->options[i]->name
      r := 100
      if val == "circle":
        s := new Shape(w/2-r/2, h/2-r/2, r, r, scene, Shape::SHAPE::CIRCLE)
      if val == "line":
        s := new Shape(w/2-r/2, h/2-r/2, r, r, scene, Shape::SHAPE::LINE)
      if val == "rect":
        s := new Shape(w/2-r/2, h/2-r/2, r, r, scene, Shape::SHAPE::SQUARE)
    }

  void redraw(bool skip_shape=false):
    app_bg->render()

  void redraw(input::SynMotionEvent &ev):
    redraw(false)


  void cleanup():
    ui::MainLoop::in.ungrab()
    app_bg->render()

  void run():
    // just to kick off the app, we do a full redraw
    ui::MainLoop::in.grab()
    ui::MainLoop::refresh()
    ui::MainLoop::redraw()
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


App app
void catch_sigint(int):
  debug "CAUGHT SIGINT"
  app.cleanup()
  exit(0)

def main():
  signal(SIGINT, catch_sigint);
  app.run()
