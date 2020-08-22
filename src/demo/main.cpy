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

    v_layout := ui::VerticalLayout(0, 0, w, h, demo_scene)
    h_layout := ui::HorizontalLayout(0, 0, w, h, demo_scene)
    h_layout.pack_center(new ui::Text(0, 0, w, 50, "Hello World"))

    pixmap := new ui::Pixmap(0, 0, 50, 50, ICON(assets::flag_solid_png))
    h_layout.pack_center(pixmap)
    v_layout.pack_center(pixmap)

  def handle_key_event(input::SynKeyEvent &key_ev):
    print "KEY PRESSED", key_ev.key

  def handle_motion_event(input::SynMouseEvent &syn_ev):
    pass

  def run():
    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)
    while true:
      ui::MainLoop::main()
      // refresh marks all widgets as dirty
      ui::MainLoop::refresh()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


def main():
  App app
  app.run()
