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

    Widget::add(new Button(10, 100, 200, 50, "tool"))
    Widget::add(new Button(10, 170, 200, 50, "eraser"))
    Widget::add(new Button(10, 240, 200, 50, "undo"))
    Widget::add(new Button(10, 310, 200, 50, "redo"))

  def handle_wacom(WacomEvent ev):
    SynEvent syn_ev;
    syn_ev.x = ev.x
    syn_ev.y = ev.y
    syn_ev.left = ev.pressure > 0
    syn_ev.right = ev.pressure == 0

    if Widget::handle_mouse_event(fb, syn_ev):
      return

    rect r = rect{ev.x, ev.y, 2, 2}
    fb.draw_rect(r, BLACK)

  def handle_mouse(MouseEvent ev):
    self.x += ev.x
    self.y += ev.y

    if self.y < 0:
      self.y = 0
    if self.x < 0:
      self.x = 0

    if self.y >= self.fb.height - 1:
      self.y = (int) self.fb.height - 5

    if self.x >= self.fb.width - 1:
      self.x = (int) self.fb.width - 5

    o_x = self.x
    o_y = self.fb.height - self.y

    if o_y >= self.fb.height - 1:
      o_y = self.fb.height - 5

    SynEvent syn_ev;
    syn_ev.x = o_x
    syn_ev.y = o_y
    syn_ev.left = ev.left
    syn_ev.right = ev.right
    if Widget::handle_mouse_event(fb, syn_ev):
      return

    fb.draw_rect(o_x, o_y, 2, 2, BLACK)

  def run():
    fb.draw_rect(0, 0, fb.width, fb.height, WHITE)
    fb.redraw_screen()

    Widget::main(fb)
    fb.redraw_screen()

    printf("HANDLING RUN\n")
    while true:
      input.listen_all()
      for auto ev : input.wacom_events:
        self.handle_wacom(ev)

      for auto ev : input.mouse_events:
        self.handle_mouse(ev)

      Widget::main(fb)
      fb.redraw_screen()


def main():
  app = App()
  app.run()

