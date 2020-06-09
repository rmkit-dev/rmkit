#include "base.h"

namespace ui:
  class Canvas: public Widget:
    public:
    int mx, my
    remarkable_color *mem
    vector<input::SynEvent> events;
    vector<shared_ptr<remarkable_color>> undo_stack;
    vector<shared_ptr<remarkable_color>> redo_stack;
    input::SynEvent last_ev
    int byte_size

    framebuffer::FBRect dirty_rect
    shared_ptr<framebuffer::VirtualFB> vfb

    Canvas(int x, y, w, h): Widget(x,y,w,h):
      px_width, px_height = self.fb->get_display_size()
      self.byte_size = px_width * px_height * sizeof(remarkable_color)
      vfb = make_shared<framebuffer::VirtualFB>()
      self.mem = (remarkable_color*) malloc(sizeof(remarkable_color) * w * h)
      fbcopy = shared_ptr<remarkable_color>((remarkable_color*) malloc(self.byte_size))
      memcpy(fbcopy.get(), self.fb->fbmem, self.byte_size)
      memcpy(vfb->fbmem, self.fb->fbmem, self.byte_size)

      self.undo_stack.push_back(fbcopy)
      reset_dirty(self.dirty_rect)

    ~Canvas():
      if self.mem != NULL:
        free(self.mem)
      self.mem = NULL

    bool ignore_event(input::SynEvent &ev):
      return input::is_touch_event(ev) != NULL

    void on_mouse_move(input::SynEvent &ev):
      stroke = 4
      if ev.original != NULL:
        if last_ev.original != NULL:
          fb->draw_line(last_ev.x, last_ev.y, ev.x,ev.y, stroke, BLACK)
          vfb->draw_line(last_ev.x, last_ev.y, ev.x,ev.y, stroke, BLACK)
        else:
          fb->draw_rect(ev.x, ev.y, stroke, stroke, BLACK)
          vfb->draw_rect(ev.x, ev.y, stroke, stroke, BLACK)
        update_dirty(self.dirty_rect, ev.x, ev.y)
      last_ev = ev

    void on_mouse_up(input::SynEvent &ev):
      finish_stroke()

    void on_mouse_hover(input::SynEvent &ev):
      pass

    void finish_stroke():
      push_undo()

      input::SynEvent null_ev
      null_ev.original = NULL
      last_ev = null_ev

    void redraw():
      memcpy(self.fb->fbmem, vfb->fbmem, self.byte_size)

    void push_undo():
      print "ADDING TO UNDO STACK, DIRTY AREA IS", \
        dirty_rect.x0, dirty_rect.y0, dirty_rect.x1, dirty_rect.y1
      fbcopy = shared_ptr<remarkable_color>((remarkable_color*) malloc(self.byte_size))
      memcpy(fbcopy.get(), vfb->fbmem, self.byte_size)
      self.undo_stack.push_back(fbcopy)
      reset_dirty(self.dirty_rect)

    void undo():
      if self.undo_stack.size() > 1:
        // put last fb from undo stack into fb
        self.redo_stack.push_back(self.undo_stack.back())
        self.undo_stack.pop_back()
        undofb = self.undo_stack.back()
        memcpy(self.fb->fbmem, undofb.get(), self.byte_size)
        memcpy(vfb->fbmem, undofb.get(), self.byte_size)
        ui::MainLoop::full_refresh()

    void redo():
      if self.redo_stack.size() > 0:
        redofb = self.redo_stack.back()
        self.redo_stack.pop_back()
        memcpy(self.fb->fbmem, redofb.get(), self.byte_size)
        memcpy(vfb->fbmem, redofb.get(), self.byte_size)
        self.undo_stack.push_back(redofb)
        ui::MainLoop::full_refresh()
