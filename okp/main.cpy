#include "mxcfb.h"
import fb
import input

using namespace std

class App:
  FB fb
  Input input

  int x = 0
  int y = 0


  public:
  def handle_wacom(auto ev):
    rect r = rect{ev.x, ev.y, 2, 2}
    fb.draw_rect(r, BLACK)

  def handle_mouse(auto ev):
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

    fb.draw_rect(o_x, o_y, 2, 2, BLACK)

  def run():
    fb.draw_rect(0, 0, fb.width, fb.height, WHITE)
    fb.redraw_screen()

    printf("HANDLING RUN\n")
    while true:
      input.listen_all()
      for auto ev : input.wacom_events:
        self.handle_wacom(ev)

      for auto ev : input.mouse_events:
        self.handle_mouse(ev)

      fb.redraw_if_dirty()


def main():
  app = App()
  app.run()

