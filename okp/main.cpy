#include "mxcfb.h"
#include "fb.h"
#include "input.h"
#include "ui.h"
#include "widgets.h"
#include "app_ui.h"

using namespace std

class App:
  shared_ptr<framebuffer::FB> fb
  input::Input in

  int x = 0
  int y = 0


  public:
  App():
    #ifndef DEV
    fb = make_shared<framebuffer::HardwareFB>()
    #else
    fb = make_shared<framebuffer::FileFB>()
    #endif

    known ui::Widget::fb = fb.get()
    known input::Input::fb = fb.get()

    fb->clear_screen()

    ui::Canvas *c = new ui::Canvas(0, 0, fb->width, fb->height)
    ui::MainLoop::add(new ui::Text(10, 10, fb->width, 50, "rmHarmony"))

    ui::MainLoop::add(new app_ui::ToolButton(10, 100, 200, 50, c))
    ui::MainLoop::add(new app_ui::UndoButton(10, 170, 200, 50, c))
    ui::MainLoop::add(new app_ui::RedoButton(10, 240, 200, 50, c))

    ui::MainLoop::add(c)


  def handle_key_event(input::KeyEvent &key_ev):
    if key_ev.is_pressed && key_ev.key == KEY_HOME:
      fb->clear_screen()
      ui::MainLoop::refresh()

  def handle_motion_event(input::SynEvent &syn_ev):
    #ifdef DEBUG_INPUT
    if (auto m_ev = input::is_mouse_event(syn_ev)):
      print "MOUSE EVENT"
    else if (auto t_ev = input::is_touch_event(syn_ev)):
      print "TOUVCH EVENT"
    else if (auto w_ev = input::is_wacom_event(syn_ev)):
      print "WACOM EVENT"
    #endif

    ui::MainLoop::handle_motion_event(syn_ev)

  def run():
    ui::MainLoop::main()
    self.fb->redraw_screen()

    printf("HANDLING RUN\n")
    while true:
      in.listen_all()
      for auto ev : in.all_motion_events:
        self.handle_motion_event(ev)

      for auto ev : in.all_key_events:
        self.handle_key_event(ev)

      ui::MainLoop::main()
      self.fb->redraw_screen()


def main():
  app = App()
  app.run()

