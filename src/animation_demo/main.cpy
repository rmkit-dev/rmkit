#include <cstddef>
#include "../build/rmkit.h"

#include <unistd.h>
using namespace std

class CircleAnimation : public ui::Widget:
  public:
  int size = 1
  int loops = -1
  int color = BLACK
  int dir = 1
  shared_ptr<ui::Pixmap> img
  CircleAnimation(int x, y, w, h) : ui::Widget(x, y, w, h):
    pass

  void animate():

    size += 1 * dir;
    if size >= 200 || size <= 0:
      dir *= -1
      if size <= 0:
        if loops > 0:
          loops--
          if loops == 0:
            return

      if color == BLACK:
        color = WHITE
      else:
        color = BLACK

    ui::TaskQueue::add_task([=]() {
      if self.loops == 0:
        self.undraw()

      self.fb->draw_circle(self.x+self.w/2, self.y+self.h/2, self.size, 1, self.color, 0 /* fill */)

      usleep(1000 * 16)
      self.animate()
    })

  void render():
    return

class Launcher: public ui::Widget:
  public:
  ui::Scene scene
  Launcher(int x, y, w, h, ui::Scene s): ui::Widget(x, y, w, h):
    self.scene = s

  void on_mouse_click(input::SynMotionEvent &ev):
    a := new CircleAnimation(ev.x, ev.y, 1, 1)
    self.scene->add(a)
    a->animate()
    a->loops = 1

class App:
  public:
  ui::Scene demo_scene


  App():
    demo_scene = ui::make_scene()
    ui::MainLoop::set_scene(demo_scene)
    fb := framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    fw, fh := fb->get_display_size()

    a := new CircleAnimation(fw/2, fh/2, 1, 1)
    demo_scene->add(a)
    a->animate()

    touch_area := new Launcher(0, 0, fw, fh, demo_scene)
    demo_scene->add(touch_area)

//    b := new Animation(200, 200, 200, 200)
//    demo_scene->add(b)
//    b->animate()




  def handle_key_event(input::SynKeyEvent &key_ev):
    debug "KEY PRESSED", key_ev.key

  def handle_motion_event(input::SynMotionEvent &syn_ev):
    pass

  def run():
    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)

    // just to kick off the app, we do a full redraw
    ui::MainLoop::refresh()
    ui::MainLoop::redraw()
    while true:
      ui::MainLoop::main()
      ui::MainLoop::refresh()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


def main():
  App app
  app.run()
