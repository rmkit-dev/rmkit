#include "base.h"
#include "brush.h"

#ifdef REMARKABLE
#define UNDO_STACK_SIZE 10
#else
#define UNDO_STACK_SIZE 100
#endif
namespace ui:
  class Canvas: public Widget:
    public:
    remarkable_color *mem
    deque<shared_ptr<remarkable_color>> undo_stack;
    deque<shared_ptr<remarkable_color>> redo_stack;
    int byte_size

    bool erasing = false

    framebuffer::FBRect dirty_rect
    shared_ptr<framebuffer::VirtualFB> vfb

    Brush* curr_brush
    Brush* eraser

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

      self.set_brush(brush::PENCIL)
      self.eraser = brush::ERASER
      self.eraser->set_stroke_width(stroke::Size::MEDIUM)

    ~Canvas():
      if self.mem != NULL:
        free(self.mem)
      self.mem = NULL

    void set_stroke_width(int s):
      self.curr_brush->set_stroke_width(s)

    auto get_stroke_width():
      return self.curr_brush->stroke_val

    void set_stroke_color(int color):
      self.curr_brush->color = color

    auto get_stroke_color():
      return self.curr_brush->color

    void reset():
      push_undo()
      memset(self.fb->fbmem, WHITE, self.byte_size)
      memset(vfb->fbmem, WHITE, self.byte_size)
      self.curr_brush->reset()

    void set_brush(Brush* brush):
      self.curr_brush = brush
      brush->reset()
      brush->set_framebuffer(self.vfb.get())

    bool ignore_event(input::SynEvent &ev):
      return input::is_touch_event(ev) != NULL

    void on_mouse_move(input::SynEvent &ev):
      brush = self.erasing ? self.eraser : self.curr_brush
      brush->stroke(ev.x, ev.y)
      brush->update_last_pos(ev.x, ev.y)
      self.dirty = 1

    void on_mouse_up(input::SynEvent &ev):
      brush = self.erasing ? self.eraser : self.curr_brush
      brush->stroke_end()
      self.push_undo()
      brush->update_last_pos(-1,-1)
      self.dirty = 1
      ui::MainLoop::full_refresh()

    void on_mouse_hover(input::SynEvent &ev):
      pass

    void on_mouse_down(input::SynEvent &ev):
      self.erasing = ev.eraser && ev.eraser != -1
      brush = self.erasing ? self.eraser : self.curr_brush
      brush->stroke_start(ev.x, ev.y)
      brush->update_last_pos(ev.x, ev.y)

    void mark_redraw():
      self.dirty = 1
      vfb->dirty_area = {0, 0, self.fb->width, self.fb->height}

    void redraw():
      memcpy(self.fb->fbmem, vfb->fbmem, self.byte_size)
      self.fb->dirty_area = vfb->dirty_area
      self.fb->dirty = 1
      framebuffer::reset_dirty(vfb->dirty_area)


    // {{{ UNDO / REDO STUFF
    void trim_stacks():
      while UNDO_STACK_SIZE > 0 && self.undo_stack.size() > UNDO_STACK_SIZE:
        self.undo_stack.pop_front()
      while UNDO_STACK_SIZE > 0 && self.redo_stack.size() > UNDO_STACK_SIZE:
        self.redo_stack.pop_front()

    void push_undo():
      dirty_rect = self.vfb->dirty_area
      print "ADDING TO UNDO STACK, DIRTY AREA IS", \
        dirty_rect.x0, dirty_rect.y0, dirty_rect.x1, dirty_rect.y1
      fbcopy = shared_ptr<remarkable_color>((remarkable_color*) malloc(self.byte_size))
      memcpy(fbcopy.get(), vfb->fbmem, self.byte_size)
      self.undo_stack.push_back(fbcopy)

      trim_stacks()
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
    // }}}
