#include "mxcfb.h"
#include "fb.h"
#include "input.h"
#include "ui.h"
#include "app_ui.h"

using namespace std

class App:
  shared_ptr<FB> fb
  Input input
  vector<Widget> widgets

  int x = 0
  int y = 0


  public:
  App():
    #ifndef DEV
    fb = make_shared<HardwareFB>()
    #else
    fb = make_shared<FileFB>()
    #endif

    known Widget::fb = fb.get()
    known Input::fb = fb.get()

    fb->clear_screen()

    Canvas *c = new Canvas(0, 0, fb->width, fb->height)
    Widget::add(new Text(10, 10, fb->width, 50, "rmHarmony"))

    Widget::add(new ToolButton(10, 100, 200, 50, c))
    Widget::add(new UndoButton(10, 170, 200, 50, c))
    Widget::add(new RedoButton(10, 240, 200, 50, c))

    Widget::add(c)


  def handle_key_event(KeyEvent &key_ev):
    if key_ev.is_pressed && key_ev.key == KEY_HOME:
      fb->clear_screen()
      Widget::refresh()

  def handle_motion_event(SynEvent &syn_ev):
    #ifdef DEBUG_INPUT
    if (auto m_ev = Input::is_mouse_event(syn_ev)):
      print "MOUSE EVENT"
    else if (auto t_ev = Input::is_touch_event(syn_ev)):
      print "TOUVCH EVENT"
    else if (auto w_ev = Input::is_wacom_event(syn_ev)):
      print "WACOM EVENT"
    #endif

    Widget::handle_motion_event(syn_ev)

  def run():
    Widget::main(*fb)
    self.fb->redraw_screen()

    printf("HANDLING RUN\n")
    while true:
      input.listen_all()
      for auto ev : input.all_motion_events:
        self.handle_motion_event(ev)

      for auto ev : input.all_key_events:
        self.handle_key_event(ev)

      Widget::main(*fb)
      self.fb->redraw_screen()


def main():
  app = App()
  app.run()

