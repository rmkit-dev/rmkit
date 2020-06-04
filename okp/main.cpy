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
    new Button(100, 100, 200, 50, "tool")
    new Button(100, 170, 200, 50, "eraser")
    new Button(100, 240, 200, 50, "undo")
    new Button(100, 310, 200, 50, "redo")

  def handle_wacom(WacomEvent ev):
    if ev.pressure == 0:
      return

    if Widget::handle_click(ev.x, ev.y):
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

    // we don't do any more mouse processing if its not a click
    if ev.left == 0:
      return

    o_x = self.x
    o_y = self.fb.height - self.y

    if o_y >= self.fb.height - 1:
      o_y = self.fb.height - 5

    if Widget::handle_click(o_x, o_y):
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

