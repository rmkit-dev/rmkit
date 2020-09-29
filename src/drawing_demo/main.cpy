#include <iostream>
#include "../build/rmkit.h"

class Note: public ui::Widget:
  public:
  int prevx = -1, prevy = -1
  Note(int x, y, w, h): Widget(x, y, w, h):
    pass

  void on_mouse_up(input::SynMouseEvent &ev):
    prevx = prevy = -1

  void on_mouse_move(input::SynMouseEvent &ev):
    if not mouse_down:
      return

    if prevx != -1:
      fb->draw_line(prevx, prevy, ev.x, ev.y, 1, BLACK)

    prevx = ev.x
    prevy = ev.y

class App:
  public:
  App():
    demo_scene := ui::make_scene()
    ui::MainLoop::set_scene(demo_scene)

    fb := framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    w, h = fb->get_display_size()

    note := new Note(0, 0, w, h)
    demo_scene->add(note)


  def handle_key_event(input::SynKeyEvent ev):
    // pressing any button will clear the screen
    ui::MainLoop::fb->clear_screen()

  def run():
    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)

    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()

app := App()
int main():
  app.run()
