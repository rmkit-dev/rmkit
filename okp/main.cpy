#include "mxcfb.h"
#include "fb.h"
#include "input.h"
#include "ui.h"
#include "app_ui.h"

using namespace std

class App:
  FB fb
  Input input
  vector<Widget> widgets

  int x = 0
  int y = 0


  public:
  App():
    known Widget::fb = &fb
    known Input::fb = &fb

    fb.draw_rect(0, 0, fb.width, fb.height, WHITE)
    fb.redraw_screen()

    Canvas *c = new Canvas(0, 0, fb.width, fb.height)
    Widget::add(new Text(10, 10, fb.width, 50, "reHarmony"))

    Widget::add(new ToolButton(10, 100, 200, 50, c))
    Widget::add(new UndoButton(10, 170, 200, 50, c))
    Widget::add(new RedoButton(10, 240, 200, 50, c))

    Widget::add(c)


  def handle_event(SynEvent &syn_ev):
    #ifdef DEBUG_INPUT
    if (auto m_ev = Input::is_mouse_event(syn_ev)):
      print "MOUSE EVENT"
    else if (auto t_ev = Input::is_touch_event(syn_ev)):
      print "TOUVCH EVENT"
    else if (auto w_ev = Input::is_wacom_event(syn_ev)):
      print "WACOM EVENT"
    #endif

    Widget::handle_mouse_event(syn_ev)

  def run():
    Widget::main(fb)
    fb.redraw_screen()

    printf("HANDLING RUN\n")
    while true:
      input.listen_all()
      for auto ev : input.all_events:
        self.handle_event(ev)

      Widget::main(fb)
      fb.redraw_screen()


def main():
  app = App()
  app.run()

