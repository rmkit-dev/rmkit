#include "base.h"
#include "scene.h"
#include "../input/events.h"

#define DEBUG_LAYOUT
namespace ui:
  class Layout: public Widget:
    public:
    Scene scene
    vector<shared_ptr<Widget>> children
    int padding = 0

    Layout(int x, y, w, h, Scene s): Widget(x,y,w,h), scene(s):
      pass

    void add(Widget *w):
      sp = shared_ptr<Widget>(w)
      children.push_back(sp)
      scene->add(sp)

    void hide():
      for auto w: children:
        w->hide()
      self.visible = false

    void show():
      for auto w: children:
        w->show()
      self.visible = true

    // Layouts generally don't receive events
    bool ignore_event(input::SynMouseEvent &ev):
      return true

  class AbsLayout: public Layout:
    public:
    AbsLayout(int x, y, w, h, Scene s): Layout(x,y,w,h,s):
      pass

  class AutoLayout: public Layout:
    public:
    int start = 0, end = 0
    AutoLayout(int x, y, w, h, Scene s): Layout(x,y,w,h,s):
      pass

    virtual void pack_start(Widget *w, int padding=0):
      pass
    virtual void pack_end(Widget *w, int padding=0):
      pass

  class VerticalLayout: public AutoLayout:
    public:
    VerticalLayout(int x, y, w, h, Scene s): AutoLayout(x,y,w,h,s):
      self.start = 0
      self.end = h

    void pack_start(Widget *w, int padding=0):
      w->y += self.start + self.y + padding
      w->x += self.x
      self.start += w->h + padding
      self.add(w)

    void pack_end(Widget *w, int padding=0):
      w->y = self.y + self.end - w->h - padding
      w->x += self.x
      self.end -= w->h + padding
      self.add(w)

    void pack_center(Widget *w):
      leftover = self.h - w->h
      padding_y = 0
      if leftover > 0:
        padding_y = leftover / 2
      w->y = self.y + padding_y
      w->x += self.x

      self.add(w)

  class HorizontalLayout: public AutoLayout:
    public:
    HorizontalLayout(int x, y, w, h, Scene s): AutoLayout(x,y,w,h,s):
      self.start = 0
      self.end = w

    void pack_start(Widget *w, int padding=0):
      w->x += self.start + self.x + padding
      w->y += self.y
      self.start += w->w + padding
      self.add(w)

    void pack_end(Widget *w, int padding=0):
      w->x = self.x + self.end - w->w - padding
      w->y += self.y
      self.end -= w->w + padding
      self.add(w)

    void pack_center(Widget *w):
      leftover = self.w - w->w
      padding_x = 0
      if leftover > 0:
        padding_x = leftover / 2
      w->x = self.x + padding_x
      w->y += self.y
      self.add(w)

