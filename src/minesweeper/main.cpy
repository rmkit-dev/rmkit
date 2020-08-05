#include <csignal>
#define true 1
#define false 0

#include "../build/rmkit.h"

using namespace std

bool Mode = 1
template<class T>
class Cell: public ui::Widget:
  public:
  T *grid
  int i, j
  bool flagged = false
  Cell(int x, y, w, h, T *g, int i, j): grid(g), i(i), j(j), Widget(x, y, w, h):
    pass

  void redraw():
    self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, self.flagged /* fill */)

  void on_mouse_click(input::SynMouseEvent &ev):
    if (Mode)
      grid->open_cell(self.i, self.j)
    else 
      grid->toggle_flag_cell(self.i, self.j)

class Grid: public ui::Widget:
  public:
  vector<vector<Cell<Grid>*>> cells
  int n
  Grid(int x, y, w, h, n): n(n), Widget(x, y, w, h):
    pass

  void open_cell(int row, col):
    print "OPENING CELL", row, col

  void toggle_flag_cell(int row, col):
    cells[row][col]->flagged ^= 1
    print "FLAGGED CELL", row, col
    
  void make_cells(ui::Scene s):
    //# TODO: make cells here
    cells = vector<vector<Cell<Grid>*>> (n, vector<Cell<Grid>*>(n))
    jump := w/(n + 1)
    remainder := (w - jump * n) / (n + 1)

    for (int i = 0; i < n; i++)
      for (int j = 0; j < n; j++)
        cells[i][j] = new Cell<Grid>(
          x + jump * j + remainder * (j + 1),
          y + jump * i + remainder * (i + 1),
          jump,
          jump,
          self,
          i,
          j)
        s->add(cells[i][j])

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
    self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, false)

  void on_mouse_click(input::SynMouseEvent &ev):
    Mode ^= 1

class App:
  public:
  shared_ptr<framebuffer::FB> fb

  ui::Scene field_scene

  App():
    fb = framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()

    w, h = fb->get_display_size()

    field_scene = ui::make_scene()
    ui::MainLoop::set_scene(field_scene)

    n := 10

    // create the grid component and add it to the field
    grid := new Grid(0, 100, 800, 800, n)

    h_layout := ui::HorizontalLayout(0, 0, w, h, field_scene)
    h_layout.pack_center(new ui::Text(0, 0, w, 50, "MineSweeper"))
    h_layout.pack_center(grid)
    // pack cells after centering grid
    grid->make_cells(field_scene);
    // create the mouse1/mouse2 buttons
    // next steps:
    // controls for the bottom half of screen (flag vs. open bomb)
    // generate a bomb field
    // opening a bomb
    
    a := new BombButton(100, 1000, 200, 50)
    field_scene->add(a)
    //b := new MyWidget(..)
 
    ui::MainLoop::refresh()

  def handle_key_event(input::SynKeyEvent &key_ev):
    print "KEY PRESSED", key_ev.key

  def handle_motion_event(input::SynMouseEvent &syn_ev):
    pass

  def run():
    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)
    while true:
      ui::MainLoop::main()
      ui::MainLoop::refresh()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


App app
void signal_handler(int signum):
  app.fb->cleanup()
  exit(signum)

def main():
  for auto s : { SIGINT, SIGTERM, SIGABRT}:
    signal(s, signal_handler)

  app.run()

// vim:syntax=cpp
