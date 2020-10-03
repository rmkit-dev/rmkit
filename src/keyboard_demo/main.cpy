#include <cstddef>
#include "../build/rmkit.h"
#include "assets.h"
using namespace std

class App:
  public:
  ui::Scene demo_scene


  App():
    demo_scene = ui::make_scene()
    ui::MainLoop::set_scene(demo_scene)

    fb := framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    w, h = fb->get_display_size()

    // let's lay out a bunch of stuff

    v_layout := ui::VerticalLayout(0, 0, w, h, demo_scene)
    h_layout1 := ui::HorizontalLayout(0, 0, w, 50, demo_scene)
    h_layout2 := ui::HorizontalLayout(0, 0, w, 50, demo_scene)
    h_layout3 := ui::HorizontalLayout(0, 0, w, 50, demo_scene)

    v_layout.pack_start(h_layout1)
    v_layout.pack_start(h_layout2)
    v_layout.pack_start(h_layout3)

    h_layout1.pack_start(new ui::Text(0, 0, 200, 50, "Héllo world"))
    h_layout2.pack_center(new ui::Text(0, 0, 200, 50, "Hello world"))
    h_layout3.pack_end(new ui::Text(0, 0, 200, 50, "Hello world"))

    h_layout := ui::HorizontalLayout(0, 0, w, h, demo_scene)

    v_layout.pack_start(h_layout)
    // showing how an input box works
    h_layout.pack_center(new ui::TextInput(0, 50, 1000, 50))



  def handle_key_event(input::SynKeyEvent &key_ev):
    debug "KEY PRESSED", key_ev.key

  def handle_motion_event(input::SynMotionEvent &syn_ev):
    pass

  def run():

    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)

    // just to kick off the app, we do a full redraw
    ui::MainLoop::refresh()
    ui::MainLoop::redraw()
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


def main():
  App app
  app.run()
