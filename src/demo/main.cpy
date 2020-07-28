#include <csignal>

#include "../build/rmkit.h"

using namespace std

class App:
  public:
  shared_ptr<framebuffer::FB> fb

  ui::Scene demo_scene


  App():
    ui::MainLoop::redraw()

    ui::TaskQueue::add_task([=]() {
      print "STARTED APP"
    });

    demo_scene = ui::make_scene()
    ui::MainLoop::set_scene(demo_scene)

    fb = framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    w, h = fb->get_display_size()

    h_layout := ui::HorizontalLayout(0, 0, w, h, demo_scene)
    h_layout.pack_center(new ui::Text(0, 0, w, 50, "Hello World"))

    ui::MainLoop::refresh()

  def handle_key_event(input::SynKeyEvent &key_ev):
    print "KEY PRESSED", key_ev.key

  def handle_motion_event(input::SynMouseEvent &syn_ev):
    pass

  def run():
    while true:
      ui::MainLoop::main()
      ui::MainLoop::refresh()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()

      for auto ev : ui::MainLoop::motion_events:
        self.handle_motion_event(ev)

      for auto ev : ui::MainLoop::key_events:
        self.handle_key_event(ev)

App app
void signal_handler(int signum):
  app.fb->cleanup()
  exit(signum)

def main():
  for auto s : { SIGINT, SIGTERM, SIGABRT}:
    signal(s, signal_handler)

  app.run()
