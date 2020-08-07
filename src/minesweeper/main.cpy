#include <csignal>
#define true 1
#define false 0

#include "../build/rmkit.h"
#include "assets.h"

using namespace std

MODE := 1
WON := false
GRID_SIZE := 6
NB_UNOPENED := 0
GAME_STARTED := true

void new_game() // forward declaring main for usage here
class GameOverDialog: public ui::ConfirmationDialog:
  public:
  GameOverDialog(int x, y, w, h): ui::ConfirmationDialog(x, y, w, h):
    self.set_title(string((WON?"You win!" : "You lose!")))
    print WON
    self.buttons = { "NEW GAME" }
    text := "Your score is: NaN"
    self.contentWidget = new ui::MultiText(20, 20, self.w, self.h - 100, text)

  void on_button_selected(string text):
    if text == "NEW GAME":
      ui::MainLoop::hide_overlay()
      GAME_STARTED = false
      new_game() // TEMPORARY
      
  
template<class T>
class Cell: public ui::Widget:
  public:
  T *grid
  int i, j
  bool flagged = false, is_bomb = 0, opened = 0
  string neighbors = "0"
  ui::Text* textWidget

  Cell(int x, y, w, h, T *g, int i, j): grid(g), i(i), j(j), Widget(x, y, w, h):
    self.textWidget = new ui::Text(x, y, w, h, "")
    self.textWidget->justify = ui::Text::JUSTIFY::CENTER
  
  void reset():
    self.flagged = 0
    self.is_bomb = 0
    self.opened = 0
    self.neighbors = "0"

  void redraw():
    color := BLACK
    fill := 0
    if self.is_bomb && self.opened:
      color = WHITE
      fill = 1
    else if !self.is_bomb && self.opened:
      color = GRAY
      fill = 1
    else if self.flagged && !self.opened:
      color = WHITE
      fill = 1
    self.fb->draw_rect(self.x, self.y, self.w, self.h, color, fill)

    self.textWidget->text = self.neighbors
    // we need to turn int -> string here for self.neighbors
    text_width, text_height := self.textWidget->get_render_size()
    padding_y := (self.h - text_height) / 2 + text_height / 4
    if padding_y < 0:
      padding_y = 0

    self.textWidget->x = self.x
    self.textWidget->y = self.y + padding_y

    if self.opened && self.neighbors[0]-'0' > 0 && !self.is_bomb:
      self.textWidget->redraw()

    if self.flagged && !opened:
      pixmap := ui::Pixmap(self.x+5, self.y+5, self.w-20, self.h-20, ICON(assets::flag_solid_png))
      pixmap.redraw()

  void on_mouse_click(input::SynMouseEvent &ev):
    if (MODE)
      grid->open_cell(self.i, self.j)
    else 
      grid->toggle_flag_cell(self.i, self.j)

class Grid: public ui::Widget:
  public:
  vector<vector<Cell<Grid>*>> cells
  GameOverDialog *gd
  int n
  Grid(int x, y, w, h, n): n(n), Widget(x, y, w, h):
    self.gd = new GameOverDialog(0, 0, 800, 800)

  void flood(int i, int j):
    queue<pair<int,int>> qe
    qe.push({i,j})
    while (qe.size()):
      t := qe.front()
      qe.pop()
      if min(t.first,t.second) < 0 || max(t.first,t.second) >= n || cells[t.first][t.second]->opened || cells[t.first][t.second]->is_bomb:
        continue
      cells[t.first][t.second]->opened = 1
      NB_UNOPENED--
      print NB_UNOPENED
      if cells[t.first][t.second]->neighbors[0]-'0'
        continue
      for int f = -1; f <= 1; f++:
        for int g = -1; g <= 1; g++:
          qe.push({t.first+f,t.second+g})

  void open_cell(int row, col):
    if cells[row][col]->opened:
      return
    print "OPENING CELL", row, col
    if cells[row][col]->is_bomb:
      cells[row][col]->opened = 1
      end_game(0)
    if !NB_UNOPENED:
      for int i = 0; i < n; i++
        for int j = 0; j < n; j++:
          if abs(j - col) <= 1 && abs(i - row) <= 1:
            NB_UNOPENED++
            continue
          int temp = rand()%100
          if temp < 15:
            cells[i][j]->is_bomb = 1
            for int  f = -1; f <= 1; f++:
              for int g = -1; g <= 1; g++:
                if min(i+f,j+g) < 0 || max(i+f,j+g) >= n:
                  continue
                cells[i+f][j+g]->neighbors[0]++
          else:
            NB_UNOPENED++
    flood(row, col)
    if !NB_UNOPENED:
      end_game(1)

  void toggle_flag_cell(int row, col):
    cells[row][col]->flagged ^= 1
    print "FLAGGED CELL", row, col
    
  void make_cells(ui::Scene s):
    cells = vector<vector<Cell<Grid>*>> (n, vector<Cell<Grid>*>(n))
    jump := w/(n + 1)
    remainder := (w - jump * n) / (n + 1)

    for (int i = 0; i < n; i++)
      for (int j = 0; j < n; j++)
        cells[i][j] = new Cell<Grid>(
          x + jump * j + remainder * (j + 1) + 1,
          y + jump * i + remainder * (i + 1) + 1,
          jump,
          jump,
          self,
          i,
          j)
        s->add(cells[i][j])

  void end_game(bool win):
    WON = win
    self.gd = new GameOverDialog(0, 0, 800, 800)
    if !win:
      for int i = 0; i < n; i++:
        for int j = 0; j < n; j++:
          open_cell(i, j)
    gd->show()

  void redraw():
    self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false /* fill */)

  void on_mouse_click(input::SynMouseEvent &ev):
    print "CLICKED IN GRID"

class BombButton: public ui::Button:
  public:
  BombButton(int x, y, w, h, string t="Observe"): Button(x,y,w,h,t):
    pass
  
  void redraw():
    ui::Button::redraw()
    self.fb->draw_rect(self.x, self.y, self.w, self.h, GRAY, MODE)

  void on_mouse_click(input::SynMouseEvent &ev):
    MODE = 1

class FlagButton: public ui::Button:
  public:
  FlagButton(int x, y, w, h, string t="Flag"): Button(x,y,w,h,t):
    pass

  void redraw():
    ui::Button::redraw()
    self.fb->draw_rect(self.x, self.y, self.w, self.h, GRAY, !MODE)

  void on_mouse_click(input::SynMouseEvent &ev):
    MODE = 0

class App:
  public:
  shared_ptr<framebuffer::FB> fb

  ui::Scene field_scene
  Grid *grid

  App():
    fb = framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()

    w, h = fb->get_display_size()

    field_scene = ui::make_scene()
    ui::MainLoop::set_scene(field_scene)

    // create the grid component and add it to the field
    grid = new Grid(0, 300, 1100, 1100, GRID_SIZE)
    NB_UNOPENED = 0

    h_layout := ui::HorizontalLayout(0, 0, w, h, field_scene)
    h_layout.pack_center(new ui::Text(0, 0, w, 50, "MineSweeper"))
    h_layout.pack_center(grid)
    // pack cells after centering grid
    grid->make_cells(field_scene)
    // create the mouse1/mouse2 buttons
    // next steps:
    // controls for the bottom half of screen (flag vs. open bomb)
    // generate a bomb field
    // opening a bomb
    
    a := new BombButton(200, 1450, 200, 50) 
    b := new FlagButton(500, 1450, 200, 50)
    field_scene->add(a)
    field_scene->add(b)
 
    ui::MainLoop::refresh()

  def reset():
    MODE = 1
    NB_UNOPENED = 0
    n := GRID_SIZE
    for int i = 0; i < n; i++
      for int j = 0; j < n; j++:
        grid->cells[i][j]->is_bomb = 0
        grid->cells[i][j]->opened = 0
        grid->cells[i][j]->flagged = 0
        grid->cells[i][j]->neighbors = "0"

  def handle_key_event(input::SynKeyEvent &key_ev):
    // print "KEY PRESSED", key_ev.key
    pass

  def handle_motion_event(input::SynMouseEvent &syn_ev):
    if !GAME_STARTED:
      if syn_ev.left == 0:
        GAME_STARTED = true
      else:
        syn_ev.stop_propagation()

  def run():
    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)
    while true:
      ui::MainLoop::main()
      ui::MainLoop::refresh()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


App app
void new_game():
  app.reset()
  app.fb->clear_screen()

def main():
  ui::Text::FS = 32
  new_game()
  app.run()

// vim:syntax=cpp
