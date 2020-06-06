#include "mxcfb.h"
import fb
import input
import ui

using namespace std


class App:
  FB fb
  Input input
  vector<Widget> widgets

  int x = 0
  int y = 0


  public:
  App():
    Widget::add(new Text(10, 10, fb.width, 50, "reHarmony"))
    Widget::add(new Canvas(0, 0, fb.width, fb.height))

    Widget::add(new Button(10, 100, 200, 50, "tool"))
    Widget::add(new Button(10, 170, 200, 50, "eraser"))
    Widget::add(new Button(10, 240, 200, 50, "undo"))
    Widget::add(new Button(10, 310, 200, 50, "redo"))

    known Widget::fb = &fb
    known Input::fb = &fb

  def handle_event(SynEvent &syn_ev):
//    if (auto m_ev = Input::is_mouse_event(syn_ev)):
//      print "MOUSE EVENT"
//    else if (auto t_ev = Input::is_touch_event(syn_ev)):
//      print "TOUVCH EVENT"
//    else if (auto w_ev = Input::is_wacom_event(syn_ev)):
//      print "WACOM EVENT"

    Widget::handle_mouse_event(fb, syn_ev)

  def run():
    fb.draw_rect(0, 0, fb.width, fb.height, WHITE)
    fb.redraw_screen()

    Widget::main(fb)
    fb.redraw_screen()

    printf("HANDLING RUN\n")
    while true:
      input.listen_all()
      for auto ev : input.events:
        self.handle_event(ev)

      Widget::main(fb)
      fb.redraw_screen()


def main():
  app = App()
  app.run()

