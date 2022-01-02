## A simple drawing program

```
#include <iostream>
#include "../build/rmkit.h"

class Note: public ui::Widget:
  public:
  int prevx = -1, prevy = -1
  framebuffer::FB *vfb
  bool full_redraw
  Note(int x, y, w, h): Widget(x, y, w, h):
    vfb = new framebuffer::VirtualFB(self.fb->width, self.fb->height)
    self.full_redraw = true

  void on_mouse_up(input::SynMotionEvent &ev):
    prevx = prevy = -1

  void on_mouse_move(input::SynMotionEvent &ev):
    if input::is_touch_event(ev):
      return

    if not mouse_down:
      return

    if prevx != -1:
      vfb->draw_line(prevx, prevy, ev.x, ev.y, 1, BLACK)
      self.dirty = 1

    prevx = ev.x
    prevy = ev.y

  void render():
    if self.full_redraw:
      self.full_redraw = false
      memcpy(self.fb->fbmem, vfb->fbmem, vfb->byte_size)
      return

    dirty_rect := self.vfb->dirty_area
    for int i = dirty_rect.y0; i < dirty_rect.y1; i++:
      memcpy(&fb->fbmem[i*fb->width + dirty_rect.x0], &vfb->fbmem[i*fb->width + dirty_rect.x0],
        (dirty_rect.x1 - dirty_rect.x0) * sizeof(remarkable_color))
    self.fb->dirty_area = vfb->dirty_area
    self.fb->dirty = 1
    vfb->reset_dirty(vfb->dirty_area)

class App:
  public:
  Note *note

  App():
    demo_scene := ui::make_scene()
    ui::MainLoop::set_scene(demo_scene)

    fb := framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    w, h = fb->get_display_size()

    note = new Note(0, 0, w, h)
    demo_scene->add(note)


  def handle_key_event(input::SynKeyEvent ev):
    // pressing any button will clear the screen
    note->vfb->clear_screen()
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
```

walking through the above, notice that there is now a Note which inherits from
ui::Widget. in rmkit, all widgets share ui::Widget as their base class, but
most inherit from more complicated ones. Notice that the Note creates a
VirtualFB - this is a virtual framebuffer - it's useful for when you want to
draw to the framebuffer but also save what you drew for later.

ui::Widget has several important functions, mainly: `render` and the
`on_mouse_*` handlers. 

In this example, the Note is the size of the whole screen, so we use the
framebuffer's display size when constructing the Note


