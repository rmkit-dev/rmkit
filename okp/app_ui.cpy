#include "ui/button.h"
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

    void on_select(int idx):
      self.canvas->set_brush(self.options[idx])


  class BrushConfigButton: public ui::TextDropdown:
    public:
    ui::Canvas *canvas
    BrushConfigButton(int x, y, w, h, ui::Canvas *c): \
      ui::TextDropdown(x,y,w,h)
      self.canvas = c

      for auto b : ui::stroke::SIZES:
        self.add_options({b->name})
      self.add_section("size")

      self.add_options({"black", "gray", "white"})
      self.add_section("color")

    void on_select(int i):
      option = self.options[i]->name
      do {
        if option == ui::stroke::FINE.name:
          self.canvas->set_stroke_width(ui::stroke::FINE.val)
          break
        if option == ui::stroke::MEDIUM.name:
          self.canvas->set_stroke_width(ui::stroke::MEDIUM.val)
          break
        if option == ui::stroke::WIDE.name:
          self.canvas->set_stroke_width(ui::stroke::WIDE.val)
          break

        if option == "black":
          self.canvas->set_stroke_color(BLACK)
          break
        if option == "white":
          self.canvas->set_stroke_color(WHITE)
          break
        if option == "gray":
          self.canvas->set_stroke_color(GRAY)
          break
      } while(false);

      self.text = option

    // sync the brush stroke to the canvas
    void before_redraw():
      idx = 0
      for auto size : ui::stroke::SIZES:
        if canvas->get_stroke_width() == size->val:
          self.text = size->name
          break
        idx++

      idx %= self.options.size()


  class LiftBrushButton: public ui::Button:
    public:
    ui::Canvas *canvas
    LiftBrushButton(int x, int y, int w, int h, ui::Canvas *c): \
        ui::Button(x,y,w,h,"lift"):
      self.canvas = c

    void on_mouse_click(input::SynEvent &ev):
      self.dirty = 1
      self.canvas->curr_brush->reset()

  string UNDO = "undo", CLEAR = "clear", REDO = "redo", SAVE = "save", DOTS = "..."
  class ManageButton: public ui::TextDropdown:
    public:
    ui::Canvas *canvas
    ManageButton(int x, y, w, h, ui::Canvas *c): TextDropdown(x,y,w,h)
      self.canvas = c
      self.add_options({DOTS, CLEAR, SAVE})
      self.text = "..."

    void on_select(int i):
      option = self.options[i]->name
      if option == CLEAR:
        self.canvas->reset()

      self.text = "..."

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
