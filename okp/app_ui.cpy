#include "ui/widgets.h"
#include "ui/scene.h"
#include "ui/ui.h"
#include "ui/dropdown.h"

namespace app_ui:

  class ToolButton: public ui::DropdownButton<ui::Brush*>:
    public:
    ui::Canvas *canvas
    ToolButton(int x, y, w, h, ui::Canvas *c): \
      ui::DropdownButton<ui::Brush*>(x,y,w,h,ui::brush::BRUSHES)
      self.canvas = c
      self.set_justification(ui::Text::JUSTIFY::LEFT)

    void on_select(int idx):
      self.canvas->set_brush(self.options[idx])


  class BrushSizeButton: public ui::DropdownButton<ui::stroke::Size*>:
    public:
    ui::Canvas *canvas
    BrushSizeButton(int x, y, w, h, ui::Canvas *c): \
      ui::DropdownButton<ui::stroke::Size*>(x,y,w,h,ui::stroke::SIZES)
      self.canvas = c

    void on_select(int idx):
      self.canvas->set_stroke_width(self.options[idx]->val)

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
    HideButton(int x, y, w, h, ui::Layout *l, *m): ui::Button(x,y,w,h,"v"):
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
      self.text = self.toolbar->visible ? "v" : "^"
      ui::Button::redraw()
