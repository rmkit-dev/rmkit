#include "widget.h"
#include "scene.h"
#include "../input/events.h"

#define DEBUG_LAYOUT
namespace ui:
  class Layout:
    public:
    Scene scene
    vector<shared_ptr<Widget>> children
    int padding = 0
    int x, y, w, h
    bool visible = true

    Layout(int x, y, w, h, Scene s): x(x), y(y), w(w), h(h), scene(s):
      pass

    shared_ptr<Widget> add(Widget *w):
      sp := shared_ptr<Widget>(w)
      children.push_back(sp)
      scene->add(sp)
      return sp

    void hide():
      for auto w: children:
        w->hide()
      self.visible = false

    void show():
      for auto w: children:
        w->show()
      self.visible = true

    void refresh():
      for auto ch : children:
        ch->dirty = 1

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
    virtual void pack_center(Widget *w):
      pass
    virtual void pack_end(Widget *w, int padding=0):
      pass

    virtual void pack_start(Layout &w, int padding=0):
      pass
    virtual void pack_center(Layout &l):
      pass
    virtual void pack_end(Layout &l, int padding=0):
      pass

    // Layout pointer overloads for backwards compatibility
    void pack_start(Layout *l, int padding=0):
      pack_start(*l, padding)
    void pack_center(Layout *l):
      pack_center(*l)
    void pack_end(Layout *l, int padding=0):
      pack_end(*l, padding)

  // class: ui::VerticalLayout
  // --- Prototype ---
  // class ui::VerticalLayout: public ui::AutoLayout:
  // -----------------
  // the vertical layout is used for packing widgets
  // vertically (top to bottom). it implements only 3 functions: pack_start,
  // pack_end and pack_center
  //
  class VerticalLayout: public AutoLayout:
    public:
    using AutoLayout::pack_start
    using AutoLayout::pack_center
    using AutoLayout::pack_end
    // function: Constructor
    //
    // Parameters:
    //
    // x - x coord of the layout's top right corner
    // y - y coord of the layout's top left corner
    // w - width of the layout
    // h - height of the layout
    // s - the scene that the layout is adding widgets to
    VerticalLayout(int x, y, w, h, Scene s): AutoLayout(x,y,w,h,s):
      self.start = 0
      self.end = h

    // function: pack_start
    // put this widget at the start of the layout
    void pack_start(Widget *w, int padding=0):
      w->y += self.start + self.y + padding
      w->x += self.x
      self.start += w->h + padding
      self.add(w)

    // function: pack_end
    // put this widget at the end of the layout
    void pack_end(Widget *w, int padding=0):
      w->y = self.y + self.end - w->h - padding
      w->x += self.x
      self.end -= w->h + padding
      self.add(w)

    // function: pack_center
    // put this widget at the center of the layout
    void pack_center(Widget *w):
      leftover := self.h - w->h
      padding_y := 0
      if leftover > 0:
        padding_y = leftover / 2
      w->y = self.y + padding_y
      w->x += self.x

      self.add(w)

    // function: pack_start
    // put this widget at the start of the layout
    void pack_start(Layout &w, int padding=0):
      w.y += self.start + self.y + padding
      w.x += self.x
      self.start += w.h + padding

    // function: pack_end
    // put this widget at the end of the layout
    void pack_end(Layout &w, int padding=0):
      w.y = self.y + self.end - w.h - padding
      w.x += self.x
      self.end -= w.h + padding

    // function: pack_center
    // put this widget at the center of the layout
    void pack_center(Layout &w):
      leftover := self.h - w.h
      padding_y := 0
      if leftover > 0:
        padding_y = leftover / 2
      w.y = self.y + padding_y
      w.x += self.x

  // class: ui::HorizontalLayout
  // --- Prototype ---
  // class ui::HorizontalLayout: public ui::AutoLayout:
  // -----------------
  // the horizontal layout is used for packing widgets
  // horizontally (left to right). it implements only 3 functions: pack_start,
  // pack_end and pack_center
  class HorizontalLayout: public AutoLayout:
    public:
    using AutoLayout::pack_start
    using AutoLayout::pack_center
    using AutoLayout::pack_end
    // function: Constructor
    //
    // Parameters:
    //
    // x - x coord of the layout's top right corner
    // y - y coord of the layout's top left corner
    // w - width of the layout
    // h - height of the layout
    // s - the scene that the layout is adding widgets to
    HorizontalLayout(int x, y, w, h, Scene s): AutoLayout(x,y,w,h,s):
      self.start = 0
      self.end = w

    // function: pack_start
    // put this widget at the start of the layout
    void pack_start(Widget *w, int padding=0):
      w->x += self.start + self.x + padding
      w->y += self.y
      self.start += w->w + padding
      self.add(w)

    // function: pack_end
    // put this widget at the end of the layout
    void pack_end(Widget *w, int padding=0):
      w->x = self.x + self.end - w->w - padding
      w->y += self.y
      self.end -= w->w + padding
      self.add(w)

    // function: pack_center
    // put this widget in the center of the layout
    void pack_center(Widget *w):
      leftover := self.w - w->w
      padding_x := 0
      if leftover > 0:
        padding_x = leftover / 2
      w->x = self.x + padding_x
      w->y += self.y
      self.add(w)

    // function: pack_start
    // put this widget at the start of the layout
    void pack_start(Layout &w, int padding=0):
      w.x += self.start + self.x + padding
      w.y += self.y
      self.start += w.w + padding

    // function: pack_end
    // put this widget at the end of the layout
    void pack_end(Layout &w, int padding=0):
      w.x = self.x + self.end - w.w - padding
      w.y += self.y
      self.end -= w.w + padding

    // function: pack_center
    // put this widget in the center of the layout
    void pack_center(Layout &w):
      leftover := self.w - w.w
      padding_x := 0
      if leftover > 0:
        padding_x = leftover / 2
      w.x = self.x + padding_x
      w.y += self.y

