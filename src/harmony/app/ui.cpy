#include <ctime>
#include "brush.h"
#include "canvas.h"
#include "dialogs.h"
#include "state.h"

namespace app_ui:

  class ToolButton: public ui::TextDropdown:
    public:
    ToolButton(int x, int y, int w, int h): \
               ui::TextDropdown(x, y, w, h, "tools"):

      ds := self.add_section("brushes")
      for auto b : brush::NP_BRUSHES:
        ds->add_options({make_pair(b->name, b->icon)})

      ds = self.add_section("procedural")
      for auto b : brush::P_BRUSHES:
        ds->add_options({make_pair(b->name, b->icon)})

      ds = self.add_section("erasers")
      for auto b : brush::ERASERS:
        ds->add_options({make_pair(b->name, b->icon)})

      self.select(0)

    void on_select(int idx):
      name := self.options[idx]->name
      for auto b : brush::P_BRUSHES:
        if b->name == name:
          STATE.brush = b
      for auto b : brush::ERASERS:
        if b->name == name:
          STATE.brush = b
      for auto b : brush::NP_BRUSHES:
        if b->name == name:
          STATE.brush = b
      self.text = ""


  class BrushConfigButton: public ui::TextDropdown:
    public:
    BrushConfigButton(int x, y, w, h): \
      ui::TextDropdown(x,y,w,h,"brush config"):
      ds := self.add_section("size")
      for auto b : stroke::SIZES:
        ds->add_options({b->name})

      ds = add_section("color")
      ds->add_options({"black", "gray1", "gray2", "gray3", "gray4", "white"})

    void on_select(int i):
      option := self.options[i]->name
      do {
        if option == stroke::FINE.name:
          STATE.stroke_width = stroke::FINE.val
          break
        if option == stroke::MEDIUM.name:
          STATE.stroke_width = stroke::MEDIUM.val
          break
        if option == stroke::WIDE.name:
          STATE.stroke_width = stroke::WIDE.val
          break

        if option == "black":
          STATE.color = BLACK
          break
        if option == "white":
          STATE.color = WHITE
          break
        if option == "gray1":
          STATE.color = color::GRAY_3
          break
        if option == "gray2":
          STATE.color = color::GRAY_6
          break
        if option == "gray3":
          STATE.color = color::GRAY_9
          break
        if option == "gray4":
          STATE.color = color::GRAY_12
          break
      } while(false);

      self.before_render()

    void render():
      sw := 1
      for auto size : stroke::SIZES:
        if STATE.stroke_width == size->val:
          sw = (size->val+1) * 5
          break

      color := STATE.color
      bg_color := color == WHITE ? BLACK : WHITE

      self.fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

      if self.mouse_inside:
        self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)

      mid_y := (self.h - sw) / 2

      self.fb->draw_line(self.x+3, self.y+mid_y-2, self.x+self.w-sw-3, self.y+mid_y-2, sw+4, bg_color)
      self.fb->draw_line(self.x+5, self.y+mid_y, self.x+self.w-sw-5, self.y+mid_y, sw, color)

  class LiftBrushButton: public ui::Button:
    public:
    Canvas *canvas
    LiftBrushButton(int x, int y, int w, int h, Canvas *c): \
        ui::Button(x,y,w,h,"lift"):
      self.canvas = c

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1
      self.canvas->curr_brush->reset()

    void before_render():
      f := std::find(brush::P_BRUSHES.begin(), brush::P_BRUSHES.end(), \
                     self.canvas->curr_brush)
      self.visible = f != brush::P_BRUSHES.end()
      ui::Button::before_render()

    void render():
      self->fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)
      ui::Button::render()
      self->fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)
      if self.mouse_down:
        self->fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, true)
      else if self.mouse_inside:
          self->fb->draw_rect(self.x, self.y, self.w, self.h, GRAY, false)

  string  ABOUT = "about",\
          CLEAR = "new",\
          DOTS  = "---",\
          QUIT  = "exit",\
          SAVE  = "save",\
          LOAD  = "load",\
          EXPORT = "export"
  class ManageButton: public ui::TextDropdown:
    public:
    Canvas *canvas

    AboutDialog *ad = NULL
    ExitDialog *ed = NULL
    ExportDialog *exd = NULL
    SaveProjectDialog *sd = NULL
    LoadProjectDialog *ld = NULL

    ManageButton(int x, y, w, h, Canvas *c): TextDropdown(x,y,w,h,"...")
      self.canvas = c
      ds := self.add_section("")
      ds->add_options({QUIT, DOTS, CLEAR, SAVE, LOAD, EXPORT, DOTS, ABOUT})
      self.text = "..."

    void select_exit():
      if self.ed == NULL:
        self.ed = new ExitDialog(0, 0, DIALOG_WIDTH, DIALOG_HEIGHT)
      self.ed->show()
    void on_select(int i):
      option := self.options[i]->name
      if option == ABOUT:
        if self.ad == NULL:
          self.ad = new AboutDialog(0, 0, DIALOG_WIDTH, DIALOG_HEIGHT)
        self.ad->show()
      if option == CLEAR:
        self.canvas->reset()
      if option == QUIT:
        self.select_exit()
      if option == EXPORT:
        filename := self.canvas->save_png()
        if self.exd == NULL:
          self.exd = new ExportDialog(0, 0, DIALOG_WIDTH*2, DIALOG_HEIGHT)
        title := "Saved as " + filename
        self.exd->set_title(title)
        self.exd->show()
      if option == LOAD:
        self.ld = new LoadProjectDialog(0, 0, DIALOG_WIDTH, LOAD_DIALOG_HEIGHT, self.canvas)
        self.ld->populate()
        self.ld->setup_for_render()
        self.ld->show()
      if option == SAVE:
        if self.sd == NULL:
          self.sd = new SaveProjectDialog(0, 0, DIALOG_WIDTH, DIALOG_HEIGHT, self.canvas)
        self.sd->show()

      self.text = "..."

  class HistoryButton: public ui::Button:
    public:
    Canvas *canvas
    HistoryButton(int x, y, w, h, Canvas *c): ui::Button(x,y,w,h,"history"):
      self.canvas = c
      self.text = "history"

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1
      STATE.disable_history = !STATE.disable_history

    void render():
      ui::Button::render()
      if STATE.disable_history:
        self.fb->draw_line(self.x, self.y, self.w+self.x, self.h+self.y, 4, BLACK)

  class UndoButton: public ui::Button:
    public:
    Canvas *canvas
    UndoButton(int x, y, w, h, Canvas *c): ui::Button(x,y,w,h,"undo"):
      self.canvas = c
      self.icon = ICON(assets::icons_fa_arrow_left_solid_png)
      self.text = ""

    void render():
      if self.canvas->undo_stack.size() > 1:
        ui::Button::render()

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1
      self.canvas->undo()

  class PalmButton: public ui::Button:
    public:
    PalmButton(int x, y, w, h): ui::Button(x,y,w,h,"reject palm"):
      self.icon = ICON(assets::icons_fa_hand_paper_solid_png)
      self.text = ""

    void render():
      ui::Button::render()
      if STATE.reject_touch:
        self.fb->draw_line(self.x, self.y, self.w+self.x, self.h+self.y, 4, BLACK)

    void on_mouse_click(input::SynMotionEvent &ev):
      STATE.reject_touch = !STATE.reject_touch
      self.dirty = 1

  class RedoButton: public ui::Button:
    public:
    Canvas *canvas
    RedoButton(int x, y, w, h, Canvas *c): ui::Button(x,y,w,h,"redo"):
      self.canvas = c
      self.icon = ICON(assets::icons_fa_arrow_right_solid_png)
      self.text = ""

    void render():
      if self.canvas->redo_stack.size():
        ui::Button::render()

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1
      self.canvas->redo()

  class LayerButton: public ui::TextDropdown:
    public:
    Canvas *canvas
    LayerDialog *ld

    LayerButton(int x, y, w, h, Canvas *c): ui::TextDropdown(x,y,w,h,"...")
      self.canvas = c
      self.ld = new LayerDialog(0, 0, 800, 600, c)

    void before_render():
      text = canvas->layers[canvas->cur_layer].name
      ui::TextDropdown::before_render()

      self.sections.clear()
      ds := self.add_section("")

      ds->add_options({"New Layer"})
      ds->add_options({"---"})
      for i := 0; i < canvas->layers.size(); i++:
        ds->add_options({canvas->layers[i].name})
      ds->add_options({"---"})

      ds->add_options({"Manage"})

      self.scene = NULL

    void render():
      ui::TextDropdown::render()
      if !canvas->layers[canvas->cur_layer].visible:
        fb->draw_line(x, y, x+w, y+h, 4, BLACK)

    void on_select(int idx):
      name := self.options[idx]->name
      if name == "New Layer":
        self.canvas->select_layer(self.canvas->new_layer())
      else if name == "Manage":
        self.ld->populate_and_show()
      else if name == "..." or name == "---":
        pass
      else:
        canvas->select_layer(name)

  class HideButton: public ui::Button:
    public:
    ui::Layout *toolbar, *minibar
    HideButton(int x, y, w, h, ui::Layout *l, *m): ui::Button(x,y,w,h,"v"):
      self.toolbar = l
      self.minibar = m

    void on_mouse_click(input::SynMotionEvent &ev):
      self.dirty = 1

      if self.toolbar->visible:
        self.toolbar->hide()
        self.minibar->show()
      else:
        self.toolbar->show()
        self.minibar->hide()

      ui::MainLoop::full_refresh()

    void render():
      self.text = self.toolbar->visible ? "v" : "^"
      ui::Button::render()

  class Clock: public ui::Text:
    public:
    Clock(int x, y, w, h): Text(x,y,w,h,"clock"):
      self.set_style(ui::Stylesheet().justify_center())

    void before_render():
      time_t rawtime;
      struct tm * timeinfo;
      char buffer[80];

      time (&rawtime);
      timeinfo = localtime(&rawtime);

      strftime(buffer,sizeof(buffer),"%H:%M ",timeinfo);
      self.text = std::string(buffer)
