#include "ui.h"

namespace ui:
  class Text: public Widget:
    public:
    string text

    Text(int x, y, w, h, string t): Widget(x, y, w, h):
      self.text = t

    void redraw():
      freetype::image_data image;
      image.buffer = (uint32_t*) malloc(sizeof(uint32_t)*self.w*self.h)
      memset(image.buffer, WHITE, sizeof(uint32_t)*self.w*self.h)
      image.w = self.w
      image.h = self.h
      fb->draw_text(self.text, self.x, self.y, image)
      free(image.buffer)


  class Button: public Widget:
    public:
    string text
    shared_ptr<Text> textWidget

    Button(int x, y, w, h, string t): Widget(x,y,w,h):
      self.text = t
      self.textWidget = shared_ptr<Text>(new Text(x, y, w, h, t))

    void on_mouse_down(input::SynEvent &ev):
      self.dirty = 1

    void on_mouse_up(input::SynEvent &ev):
      self.dirty = 1

    void on_mouse_leave(input::SynEvent &ev):
      self.dirty = 1

    void on_mouse_enter(input::SynEvent &ev):
      self.dirty = 1

    void redraw():
      self.textWidget->text = text
      self.textWidget->set_coords(x, y, w, h)
      self.textWidget->redraw()

      color = WHITE
      if self.mouse_inside:
        color = BLACK
      fill = false
      if self.mouse_down:
        fill = true
      fb->draw_rect(self.x, self.y, self.w, self.h, color, fill)

  class Canvas: public Widget:
    public:
    int mx, my
    remarkable_color *mem
    vector<input::SynEvent> events;
    vector<remarkable_color*> undo_stack;
    vector<remarkable_color*> redo_stack;
    input::SynEvent last_ev

    framebuffer::FBRect dirty_rect
    shared_ptr<framebuffer::VirtualFB> vfb

    Canvas(int x, y, w, h): Widget(x,y,w,h):
      vfb = make_shared<framebuffer::VirtualFB>()
      self.mem = (remarkable_color*) malloc(sizeof(remarkable_color) * w * h)
      remarkable_color* fbcopy = (remarkable_color*) malloc(self.fb->byte_size)
      memcpy(fbcopy, self.fb->fbmem, self.fb->byte_size)
      memcpy(vfb->fbmem, self.fb->fbmem, self.fb->byte_size)

      self.undo_stack.push_back(fbcopy)
      reset_dirty(self.dirty_rect)

    ~Canvas():
      if self.mem != NULL:
        free(self.mem)
      self.mem = NULL

    bool ignore_event(input::SynEvent &ev):
      return input::is_touch_event(ev) != NULL

    void on_mouse_move(input::SynEvent &ev):
      events.push_back(ev)
      self.redraw()

    void on_mouse_up(input::SynEvent &ev):
      #ifdef DEV
      push_undo()
      #endif

      input::SynEvent null_ev
      null_ev.original = NULL
      self.events.push_back(null_ev)

    void on_mouse_hover(input::SynEvent &ev):
      pass

    void redraw():
      stroke = 4
      for auto ev: self.events:
        if ev.original != NULL:
          if last_ev.original != NULL:
            fb->draw_line(last_ev.x, last_ev.y, ev.x,ev.y, stroke, BLACK)
            vfb->draw_line(last_ev.x, last_ev.y, ev.x,ev.y, stroke, BLACK)
          else:
            fb->draw_rect(ev.x, ev.y, stroke, stroke, BLACK)
            vfb->draw_rect(ev.x, ev.y, stroke, stroke, BLACK)
          update_dirty(self.dirty_rect, ev.x, ev.y)
        last_ev = ev
      self.events.clear()

    void push_undo():
      print "ADDING TO UNDO STACK, DIRTY AREA IS", \
        dirty_rect.x0, dirty_rect.y0, dirty_rect.x1, dirty_rect.y1
      remarkable_color* fbcopy = (remarkable_color*) malloc(self.fb->byte_size)
      memcpy(fbcopy, self.fb->fbmem, self.fb->byte_size)
      self.undo_stack.push_back(fbcopy)
      reset_dirty(self.dirty_rect)

    void undo():
      if self.undo_stack.size() > 1:
        // put last fb from undo stack into fb
        self.redo_stack.push_back(self.undo_stack.back())
        self.undo_stack.pop_back()
        remarkable_color* undofb = self.undo_stack.back()
        memcpy(self.fb->fbmem, undofb, self.fb->byte_size)
        MainLoop::refresh()

    void redo():
      if self.redo_stack.size() > 0:
        remarkable_color* redofb = self.redo_stack.back()
        self.redo_stack.pop_back()
        memcpy(self.fb->fbmem, redofb, self.fb->byte_size)
        self.undo_stack.push_back(redofb)
        MainLoop::refresh()
