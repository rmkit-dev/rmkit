#include "../build/rmkit.h"

class SimpleCanvas: public ui::Widget:
  public:
  int prevx = -1, prevy = -1
  framebuffer::FileFB *vfb
  bool full_redraw
  SimpleCanvas(int x, y, w, h, string name="note.raw"): ui::Widget(x, y, w, h):
    vfb = new framebuffer::FileFB(name.c_str(), w, h)
    self.full_redraw = true
    self.dirty = 1

    vfb->dirty_area.x0 = 0
    vfb->dirty_area.y0 = 0
    vfb->dirty_area.x1 = self.w
    vfb->dirty_area.y1 = self.h

  void on_mouse_up(input::SynMotionEvent &ev):
    prevx = prevy = -1

  void on_mouse_leave(input::SynMotionEvent &ev):
    prevx = prevy = -1

  void on_mouse_enter(input::SynMotionEvent &ev):
    prevx = prevy = -1

  void on_mouse_move(input::SynMotionEvent &ev):
    if input::is_touch_event(ev):
      return

    if not mouse_down:
      return

    nextx := ev.x - self.x
    nexty := ev.y - self.y
    if prevx != -1:
      vfb->draw_line(prevx, prevy, nextx, nexty, 1, BLACK)

    self.dirty = 1
    prevx = nextx
    prevy = nexty

  void render():
    dirty_rect := self.vfb->dirty_area
    if dirty_rect.x1 < dirty_rect.x0 || dirty_rect.y1 < dirty_rect.y0:
      return

    for int i = dirty_rect.y0; i < dirty_rect.y1; i++:
      memcpy(
        &fb->fbmem[(y+i)*fb->width + dirty_rect.x0 + self.x], 
        &vfb->fbmem[i*vfb->width + dirty_rect.x0],
        (dirty_rect.x1 - dirty_rect.x0) * sizeof(remarkable_color))

    self.fb->update_dirty(self.fb->dirty_area, 
      vfb->dirty_area.x0 + self.x, vfb->dirty_area.y0 + self.y)
    self.fb->update_dirty(self.fb->dirty_area, 
      vfb->dirty_area.x1 + self.x, vfb->dirty_area.y1 + self.y)
    self.fb->dirty = 1

    if self.full_redraw:
      self.full_redraw = false
      self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)

    vfb->reset_dirty(vfb->dirty_area)

