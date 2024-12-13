#include "layouts.h"

#define RANGE(X) X.begin(), X.end()
namespace ui:
  class ReflowLayout: public ui::Layout:
    public:
    static unordered_map<Scene, vector<ReflowLayout*>> scene_to_layouts = {}
    vector<ReflowLayout*> layouts

    class PackedChild:
      public:
      shared_ptr<ReflowLayout> sl
      shared_ptr<Widget> sp
      int padding
    ;

    vector<PackedChild> start
    vector<PackedChild> end
    vector<PackedChild> center

    int _x, _y, _w, _h

    ReflowLayout(int x, y, w, h, Scene s): Layout(x,y,w,h,s), _x(x), _y(y), _w(w), _h(h):
      if scene_to_layouts.find(scene) == scene_to_layouts.end():
        scene_to_layouts[s] = {}
      scene_to_layouts[s].push_back(self)


    ~ReflowLayout():
      if scene_to_layouts.find(scene) != scene_to_layouts.end():
        it := find(RANGE(scene_to_layouts[scene]), self)
        if it == scene_to_layouts[scene].end():
          return

        scene_to_layouts[scene].erase(it)

    void restore_coords():
      x = _x
      y = _y
      w = _w
      h = _h

    virtual void reflow():
      pass

    shared_ptr<ReflowLayout> add(ReflowLayout *l):
      sp := shared_ptr<ReflowLayout>(l)
      return sp

    void mark_children(unordered_map<ReflowLayout*, bool> &has_parent):
      for auto l : self.layouts:
        has_parent[l] = true
        l->mark_children(has_parent)

    void pack_start(Widget* w, int padding=0):
      sp := Layout::add(w)
      self.start.push_back({NULL, sp, padding})
    void pack_end(Widget* w, int padding=0):
      sp := Layout::add(w)
      self.end.push_back({NULL, sp, padding})
    void pack_center(Widget* w, int padding=0):
      sp := Layout::add(w)
      self.center.push_back({NULL, sp, padding})

    void pack_start(ReflowLayout* w, int padding=0):
      layouts.push_back(w)
      sl := ReflowLayout::add(w)
      self.start.push_back({sl, NULL, padding})
    void pack_end(ReflowLayout* w, int padding=0):
      layouts.push_back(w)
      sl := ReflowLayout::add(w)
      self.end.push_back({sl, NULL, padding})
    void pack_center(ReflowLayout* w, int padding=0):
      layouts.push_back(w)
      sl := ReflowLayout::add(w)
      self.center.push_back({sl, NULL, padding})
  ;

  class HorizontalReflow: public ReflowLayout:
    public:
    using ReflowLayout::pack_start;
    using ReflowLayout::pack_end;
    using ReflowLayout::pack_center;

    HorizontalReflow(int x, y, w, h, Scene s): ReflowLayout(x,y,w,h,s):
      pass

    void reflow():
      offset := 0
      debug "REFLOWING HORIZONTAL"
      for auto pw : self.start:
        if pw.sp != NULL:
          padding = pw.padding
          pw.sp->x += offset + self.x + padding
          pw.sp->y += self.y
          offset += pw.sp->w + padding
          pw.sp->on_reflow()
        if pw.sl != NULL:
          padding = pw.padding
          pw.sl->x += offset + self.x + padding
          pw.sl->y += self.y
          offset += pw.sl->w + padding
          pw.sl->reflow()

      offset = self.w
      for auto pw : self.end:
        if pw.sp != NULL:
          padding = pw.padding
          pw.sp->x = self.x + offset - pw.sp->w - padding
          pw.sp->y += self.y
          offset -= pw.sp->w + padding
          pw.sp->on_reflow()
        if pw.sl != NULL:
          padding = pw.padding
          pw.sl->x = self.x + offset - pw.sl->w - padding
          pw.sl->y += self.y
          offset -= pw.sl->w + padding
          pw.sl->reflow()

      for auto pw : self.center:
        if pw.sp != NULL:
          leftover := self.w - pw.sp->w
          padding_x := 0
          if leftover > 0:
            padding_x = leftover / 2
          pw.sp->x = self.x + padding_x
          pw.sp->y += self.y
          pw.sp->on_reflow()
        if pw.sl != NULL:
          leftover := self.w - pw.sl->w
          padding_x := 0
          if leftover > 0:
            padding_x = leftover / 2
          pw.sl->x = self.x + padding_x
          pw.sl->y += self.y
          pw.sl->reflow()

  class VerticalReflow: public ReflowLayout:
    public:
    using ReflowLayout::pack_start;
    using ReflowLayout::pack_end;
    using ReflowLayout::pack_center;

    VerticalReflow(int x, y, w, h, Scene s): ReflowLayout(x,y,w,h,s):
      pass

    void reflow():
      debug "REFLOWING VERTICAL"
      offset := 0
      shared_ptr<Widget> w
      for auto pw : self.start:
        if pw.sp != NULL:
          padding := pw.padding
          pw.sp->y += offset + self.y + padding
          pw.sp->x += self.x
          offset += pw.sp->h + padding
          pw.sp->on_reflow()
        if pw.sl != NULL:
          padding := pw.padding
          pw.sl->y += offset + self.y + padding
          pw.sl->x += self.x
          offset += pw.sl->h + padding
          pw.sl->reflow()

      offset = self.h
      for auto pw : self.end:
        if pw.sp != NULL:
          padding = pw.padding
          pw.sp->y = self.y + offset - pw.sp->h - padding
          pw.sp->x += self.x
          offset -= pw.sp->h + padding
          pw.sp->on_reflow()
        if pw.sl != NULL:
          padding = pw.padding
          pw.sl->y = self.y + offset - pw.sl->h - padding
          pw.sl->x += self.x
          offset -= pw.sl->h + padding
          pw.sl->reflow()

      for auto pw : self.center:
        if pw.sp != NULL:
          leftover := self.h - pw.sp->h
          padding_y := 0
          if leftover > 0:
            padding_y = leftover / 2
          pw.sp->y = self.y + padding_y
          pw.sp->x += self.x
          pw.sp->on_reflow()
        if pw.sl != NULL:
          leftover := self.h - pw.sl->h
          padding_y := 0
          if leftover > 0:
            padding_y = leftover / 2
          pw.sl->y = self.y + padding_y
          pw.sl->x += self.x
          pw.sl->reflow()

