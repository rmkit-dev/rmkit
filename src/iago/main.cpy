#include "../build/rmkit.h"
#include "../shared/string.h"

class AppBackground: public ui::Widget:
  public:
  int byte_size, byte_size_less
  framebuffer::VirtualFB *vfb = NULL

  AppBackground(int x, y, w, h): ui::Widget(x, y, w, h):
    self.byte_size_less = w*(h-80)*sizeof(remarkable_color)
    self.byte_size = w*h*sizeof(remarkable_color)

    fw, fh := fb->get_display_size()
    vfb = new framebuffer::VirtualFB(fw, fh)
    vfb->clear_screen()
    vfb->fbmem = (remarkable_color*) memcpy(vfb->fbmem, fb->fbmem, self.byte_size)

  void render():
    full_render(true)

  void full_render(bool partial=false):
    if rm2fb::IN_RM2FB_SHIM:
      fb->waveform_mode = WAVEFORM_MODE_GC16
    else:
      fb->waveform_mode = WAVEFORM_MODE_AUTO

    if partial:
      memcpy(fb->fbmem, vfb->fbmem, self.byte_size_less)
    else:
      memcpy(fb->fbmem, vfb->fbmem, self.byte_size)

    fb->perform_redraw(true)
    fb->dirty = 1

class App:
  public:
  enum SHAPE { LINE=0, SQUARE, CIRCLE }
  int shape = LINE

  ui::Widget *handle_one, *handle_two
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

    handle_one = new ui::Text(500, h/2-10, 50, 50, "o")
    handle_two = new ui::Text(1000, h/2-10, 50, 50, "x")

    no_button := new ui::Text(0, 0, 200, 50, "cancel")
    ok_button := new ui::Text(0, 0, 200, 50, "ok")
    h_layout.pack_end(ok_button)
    h_layout.pack_end(no_button)

    shape_dropdown := new ui::TextDropdown(0, 0, 250, 50, "shapes")
    shape_dropdown->dir = ui::DropdownButton::DIRECTION::UP
    shape_dropdown->add_section("shapes")->add_options({"line", "circle", "rect"})
    h_layout.pack_center(shape_dropdown)


    no_button->set_style(style)
    ok_button->set_style(style)
    handle_one->set_style(style.font_size(50))
    handle_two->set_style(style.font_size(50))

    handle_one->mouse.move += PLS_LAMBDA(auto &ev) {
      handle_one->x = ev.x - handle_one->w/2
      handle_one->y = ev.y - handle_one->h/2
      draw_pixel(handle_one)
    }

    handle_two->mouse.move += PLS_LAMBDA(auto &ev) {
      handle_two->x = ev.x - handle_two->w/2
      handle_two->y = ev.y - handle_two->h/2
      draw_pixel(handle_two)
    }

    handle_one->mouse.up += PLS_DELEGATE(self.redraw)
    handle_two->mouse.up += PLS_DELEGATE(self.redraw)
    handle_one->mouse.leave += PLS_DELEGATE(self.redraw)
    handle_two->mouse.leave += PLS_DELEGATE(self.redraw)

    no_button->mouse.click += PLS_LAMBDA(auto &ev) {
      self.cleanup()
      exit(0)
    }

    ok_button->mouse.click += PLS_LAMBDA(auto &ev) {
      self.cleanup()
      str := redraw_shape(handle_one, handle_two, -1)
      cmd := "echo '"+ str + "' | /opt/bin/lamp"
      debug "RUNNING", cmd
      _ := system("sleep 0.5")
      _ = system(cmd.c_str())
      exit(0)
    }

    shape_dropdown->events.selected += PLS_LAMBDA(int i) {
      val := shape_dropdown->options[i]->name
      if val == "circle":
        shape = CIRCLE
      if val == "line":
        shape = LINE
      if val == "rect":
        shape = SQUARE
    }

    scene->add(handle_one)
    scene->add(handle_two)

  void draw_pixel(ui::Widget *w1):
    fb->draw_line(w1->x+w1->w/2-1, w1->y+w1->h/2-1, w1->x+w1->w/2+1, w1->y+w1->h/2+1, 3, color::GRAY_9)

  void redraw(bool skip_shape=false):
    app_bg->render()
    if not skip_shape:
      redraw_shape(handle_one, handle_two)

    handle_one->dirty = 1
    handle_two->dirty = 1

  void redraw(input::SynMotionEvent &ev):
    redraw(false)

  string redraw_shape(ui::Widget *w1, ui::Widget *w2, int color=color::GRAY_8):
    w1->dirty = 1
    w2->dirty = 1

    a1 := w1->x + w1->w/2
    b1 := w1->y + w1->h/2
    a2 := w2->x + w2->w/2
    b2 := w2->y + w2->h/2

    x1 := min(a1, a2)
    x2 := max(a1, a2)
    y1 := min(b1, b2)
    y2 := max(b1, b2)

    w := x2 - x1
    h := y2 - y1

    r := int(sqrt(w * w + h * h))

    if shape == LINE:
      if color != -1:
        fb->draw_line(a1, b1, a2, b2, 3, color)

      return "pen line " + str_utils::join(%{
        to_string(a1),
        to_string(b1),
        to_string(a2),
        to_string(b2)}, ' ')

    if shape == SQUARE:
      for i := 0; i < 3; i++:
        fb->draw_rect(x1+i, y1+i, w-i*2, h-i*2, color, /* fill */ false)

      return "fastpen rectangle " + str_utils::join(%{
        to_string(x1),
        to_string(y1),
        to_string(x2),
        to_string(y2)}, ' ')

    if shape == CIRCLE:
      fb->draw_circle(a1, b1, r, 3, color, /* fill */ false)
      return "fastpen circle " + str_utils::join(%{
        to_string(a1),
        to_string(b1),
        to_string(r),
        to_string(0)}, ' ')

    return ""

  void cleanup():
    ui::MainLoop::in.ungrab()
    app_bg->full_render()

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
