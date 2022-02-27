#include "state.h"
#include "brush.h"
#include "../../shared/snapshot.h"

#ifdef REMARKABLE
#define UNDO_STACK_SIZE 10
#else
#define UNDO_STACK_SIZE 100
#endif


namespace app_ui:

  class Canvas: public ui::Widget:
    public:
    remarkable_color *mem
    deque<shared_ptr<framebuffer::Snapshot>> undo_stack;
    deque<shared_ptr<framebuffer::Snapshot>> redo_stack;
    int byte_size
    int stroke_width = 1
    remarkable_color stroke_color = BLACK
    int page_idx = 0

    bool erasing = false
    bool full_redraw = false

    framebuffer::FBRect dirty_rect
    shared_ptr<framebuffer::FileFB> vfb

    Brush* curr_brush
    Brush* eraser

    Canvas(int x, y, w, h): ui::Widget(x,y,w,h):
      STATE.brush(PLS_DELEGATE(self.set_brush))
      STATE.color(PLS_DELEGATE(self.set_stroke_color))
      STATE.stroke_width(PLS_DELEGATE(self.set_stroke_width))

      px_width, px_height = self.fb->get_display_size()
      self.byte_size = px_width * px_height * sizeof(remarkable_color)

      fb->dither = framebuffer::DITHER::BAYER_2
      self.load_vfb()
      fbcopy := shared_ptr<remarkable_color>((remarkable_color*) malloc(self.byte_size))
      snapshot := make_shared<framebuffer::Snapshot>(w, h)
      snapshot->compress(self.fb->fbmem, self.fb->byte_size)

      self.undo_stack.push_back(snapshot)
      fb->reset_dirty(self.dirty_rect)

      self.eraser = brush::ERASER
      self.set_brush(brush::ERASER)
      self.eraser->set_stroke_width(stroke::Size::MEDIUM)

      self.set_brush(brush::PENCIL)

    ~Canvas():
      pass

    void set_stroke_width(int s):
      self.stroke_width = s
      self.curr_brush->set_stroke_width(s)

    auto get_stroke_width():
      return self.curr_brush->stroke_val

    void set_stroke_color(int color):
      self.stroke_color = color
      self.curr_brush->color = color

    auto get_stroke_color():
      return self.curr_brush->color

    void reset():
      memset(self.fb->fbmem, WHITE, self.byte_size)
      memset(vfb->fbmem, WHITE, self.byte_size)
      self.curr_brush->reset()
      push_undo()

    void set_brush(Brush* brush):
      self.curr_brush = brush
      brush->reset()
      brush->color = self.stroke_color
      brush->set_stroke_width(self.stroke_width)
      brush->set_framebuffer(self.vfb.get())

    bool ignore_event(input::SynMotionEvent &ev):
      return input::is_touch_event(ev) != NULL

    void on_mouse_move(input::SynMotionEvent &ev):
      brush := self.erasing ? self.eraser : self.curr_brush
      brush->stroke(ev.x, ev.y, ev.tilt_x, ev.tilt_y, ev.pressure)
      brush->update_last_pos(ev.x, ev.y, ev.tilt_x, ev.tilt_y, ev.pressure)
      self.dirty = 1

    void on_mouse_up(input::SynMotionEvent &ev):
      brush := self.erasing ? self.eraser : self.curr_brush
      brush->stroke_end()
      self.push_undo()
      brush->update_last_pos(-1,-1,-1,-1,-1)
      self.dirty = 1

    void on_mouse_hover(input::SynMotionEvent &ev):
      pass

    void on_mouse_down(input::SynMotionEvent &ev):
      self.erasing = ev.eraser && ev.eraser != -1
      brush := self.erasing ? self.eraser : self.curr_brush
      brush->stroke_start(ev.x, ev.y,ev.tilt_x, ev.tilt_y, ev.pressure)

    void mark_redraw():
      self.dirty = 1
      self.full_redraw = true
      px_width, px_height = self.fb->get_display_size()
      vfb->dirty_area = {0, 0, px_width, px_height}

    void render():
      dirty_rect = self.vfb->dirty_area
      for int i = dirty_rect.y0; i < dirty_rect.y1; i++:
        memcpy(&fb->fbmem[i*fb->width + dirty_rect.x0], &vfb->fbmem[i*fb->width + dirty_rect.x0],
          (dirty_rect.x1 - dirty_rect.x0) * sizeof(remarkable_color))

      self.fb->dirty_area = vfb->dirty_area
      self.fb->dirty = 1
      vfb->reset_dirty(vfb->dirty_area)

    // {{{ SAVING / LOADING
    string save():
      return self.vfb->save_lodepng()

    void load_from_png(string filename):
      self.vfb->load_from_png(filename)
      self.dirty = 1
      ui::MainLoop::full_refresh()
      self.push_undo()

    void load_vfb():
      if self.vfb != nullptr:
        msync(self.vfb->fbmem, self.byte_size, MS_SYNC)

      char filename[PATH_MAX]
      sprintf(filename, "%s/fb.%i.raw", SAVE_DIR, self.page_idx)
      self.vfb = make_shared<framebuffer::FileFB>(filename, self.fb->width, self.fb->height)
      self.vfb->dither = framebuffer::DITHER::BAYER_2
      memcpy(fb->fbmem, vfb->fbmem, self.byte_size)

      self.dirty = 1
      self.full_redraw = 1
      ui::MainLoop::refresh()

    int MAX_PAGES = 10
    void next_page():
      if self.page_idx < MAX_PAGES:
        self.page_idx++;
        self.load_vfb()

    void prev_page():
      if self.page_idx > 0:
        self.page_idx--
        self.load_vfb()
    // }}}

    // {{{ UNDO / REDO STUFF
    void trim_stacks():
      while UNDO_STACK_SIZE > 0 && self.undo_stack.size() > UNDO_STACK_SIZE:
        self.undo_stack.pop_front()
      while UNDO_STACK_SIZE > 0 && self.redo_stack.size() > UNDO_STACK_SIZE:
        self.redo_stack.pop_front()

    void push_undo():
      if STATE.disable_history:
        return

      dirty_rect = self.vfb->dirty_area
      debug "ADDING TO UNDO STACK, DIRTY AREA IS", \
        dirty_rect.x0, dirty_rect.y0, dirty_rect.x1, dirty_rect.y1
      remarkable_color* fbcopy = (remarkable_color*) malloc(self.byte_size)
      memcpy(fbcopy, vfb->fbmem, self.byte_size)
      fb->reset_dirty(self.dirty_rect)

      ui::TaskQueue::add_task([=]() {
        snapshot := make_shared<framebuffer::Snapshot>(w, h)
        snapshot->compress(fbcopy, self.byte_size)
        free(fbcopy)


        self.undo_stack.push_back(snapshot)
        self.redo_stack.clear()

        trim_stacks()
      })


    void undo():
      if self.undo_stack.size() > 1:
        // put last fb from undo stack into fb
        self.redo_stack.push_back(self.undo_stack.back())
        self.undo_stack.pop_back()
        undofb := self.undo_stack.back()
        undofb.get()->decompress(self.fb->fbmem)
        undofb.get()->decompress(vfb->fbmem)
        ui::MainLoop::full_refresh()

    void redo():
      if self.redo_stack.size() > 0:
        redofb := self.redo_stack.back()
        self.redo_stack.pop_back()
        redofb.get()->decompress(self.fb->fbmem)
        redofb.get()->decompress(vfb->fbmem)
        self.undo_stack.push_back(redofb)
        ui::MainLoop::full_refresh()
    // }}}
