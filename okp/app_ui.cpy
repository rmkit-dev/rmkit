#include "ui/widgets.h"
#include "ui/scene.h"
#include "ui/ui.h"

namespace app_ui:
  class ToolButton: public ui::Button:
    public:
    ui::Canvas *canvas
    vector<shared_ptr<ui::Brush>> tools
    int idx = 0
    ToolButton(int x, y, w, h, ui::Canvas *c): ui::Button(x,y,w,h,"tool"):
      self.canvas = c
      self.dirty = 1

      pencil = make_shared<ui::Pencil>(3)
      shaded = make_shared<ui::Shaded>(1)
      eraser = make_shared<ui::Eraser>(10)

      self.tools = {pencil, shaded, eraser}
      self.text = tools[idx]->name
      self.canvas->set_brush(tools[idx])

    void on_mouse_click(input::SynEvent&):
      idx++
      idx %= tools.size()
      self.text = tools[idx]->name
      self.canvas->set_brush(tools[idx])

  class UndoButton: public ui::Button:
    public:
    ui::Canvas *canvas
    UndoButton(int x, y, w, h, ui::Canvas *c): ui::Button(x,y,w,h,"undo"):
      self.canvas = c

    void on_mouse_click(input::SynEvent &ev):
      self.dirty = 1
      self.canvas->undo()

  class RedoButton: public ui::Button:
    public:
    ui::Canvas *canvas
    RedoButton(int x, y, w, h, ui::Canvas *c): ui::Button(x,y,w,h,"redo"):
      self.canvas = c

    void on_mouse_click(input::SynEvent &ev):
      self.dirty = 1
      self.canvas->redo()

  class HideButton: public ui::Button:
    public:
    ui::Layout *toolbar, *minibar
    HideButton(int x, y, w, h, ui::Layout *l, *m): ui::Button(x,y,w,h,"hide"):
      self.toolbar = l
      self.minibar = m

    void on_mouse_click(input::SynEvent &ev):
      self.dirty = 1

      if self.toolbar->visible:
        self.toolbar->hide()
        self.minibar->show()
      else:
        self.toolbar->show()
        self.minibar->hide()

      ui::MainLoop::full_refresh()

    void redraw():
      self.text = self.toolbar->visible ? "hide" : "show"
      ui::Button::redraw()
