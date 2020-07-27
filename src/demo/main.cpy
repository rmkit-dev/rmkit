#include <csignal>

#include "../build/rmkit.h"

using namespace std

class App:
  public:
  shared_ptr<framebuffer::FB> fb
  input::Input in

  ui::Scene demo_scene


  App():
    fb = framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    ui::TaskQueue::add_task([=]() {
      print "STARTED APP"
    });

    demo_scene = ui::make_scene()
    ui::MainLoop::set_scene(demo_scene)

  def handle_key_event(input::SynKeyEvent &key_ev):
    print "KEY PRESSED", key_ev.key
    ui::MainLoop::handle_key_event(key_ev)

  def handle_motion_event(input::SynMouseEvent &syn_ev):
    ui::MainLoop::handle_motion_event(syn_ev)

  def run():
    ui::MainLoop::main()
    self.fb->redraw_screen()

    while true:
      in.listen_all()
      for auto ev : in.all_motion_events:
        self.handle_motion_event(ev)

      for auto ev : in.all_key_events:
        self.handle_key_event(ev)

      ui::MainLoop::main()
      self.fb->redraw_screen()

App app
void signal_handler(int signum):
  app.fb->cleanup()
  exit(signum)

def main():
  for auto s : { SIGINT, SIGTERM, SIGABRT}:
    signal(s, signal_handler)

  app.run()
