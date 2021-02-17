#include "../build/rmkit.h"
#include "../shared/string.h"

#include "shapes.h"

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
