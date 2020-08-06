#include <csignal>
#define true 1
#define false 0

#include "../build/rmkit.h"

using namespace std

bool Mode = 1
int nb_moves = 0

class GameOverDialog: public ui::ConfirmationDialog:
  public:
  GameOverDialog(int x, y, w, h): ui::ConfirmationDialog(x, y, w, h):
    self.set_title(string("Game Over: ") + string("you lose"))
    text := "Your score was: 0"
    self.contentWidget = new ui::MultiText(20, 20, self.w, self.h - 100, text)
  
template<class T>
class Cell: public ui::Widget:
  public:
  T *grid
  int i, j
  bool flagged = false, is_bomb = 0, visited = 0, opened = 0
  string neighbors = "0"
  ui::Text* textWidget

  Cell(int x, y, w, h, T *g, int i, j): grid(g), i(i), j(j), Widget(x, y, w, h):
    self.textWidget = new ui::Text(x, y, w, h, "")
    self.textWidget->justify = ui::Text::JUSTIFY::CENTER

  void redraw():
    color := BLACK
    fill := 0
    if is_bomb && opened:
      color = WHITE
      fill = 1
    else if !is_bomb && opened:
      color = GRAY
      fill = 1
    else if flagged && !opened:
      color = BLACK
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

    if self.opened && self.neighbors[0]-'0' > 0:
      self.textWidget->redraw()

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

  void flood(int i, int j):
    queue<pair<int,int>> qe
    qe.push({i,j})
    while (qe.size()):
      t := qe.front()
      qe.pop()
      if min(t.first,t.second) < 0 || max(t.first,t.second) >= n || cells[t.first][t.second]->opened:
        continue
      cells[t.first][t.second]->opened = 1
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
    nb_moves++
    if nb_moves == 1:
      for int i = 0; i < n; i++
        for int j = 0; j < n; j++:
          if abs(j - col) <= 1 && abs(i - row) <= 1 
            continue
          int temp = rand()%100
          if temp <= 20:
            cells[i][j]->is_bomb = 1
            for int  f = -1; f <= 1; f++:
              for int g = -1; g <= 1; g++:
                if min(i+f,j+g) < 0 || max(i+f,j+g) >= n:
                  continue
                cells[i+f][j+g]->neighbors[0]++
    flood(row, col)

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

  void end_game(bool win):
    if win:
      return
    else:
      for int i = 0; i < n; i++:
        for int j = 0; j < n; j++:
          open_cell(i, j)
    // Open dialog

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
  GameOverDialog *gd

  App():
    fb = framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()

    w, h = fb->get_display_size()
    self.gd = new GameOverDialog(0, 0, 800, 800)

    field_scene = ui::make_scene()
    ui::MainLoop::set_scene(field_scene)

    n := 16

    // create the grid component and add it to the field
    grid := new Grid(0, 300, 1100, 1100, n)
    nb_moves = 0
    //memset(opened, 0, sizeof opened)

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
    
    a := new BombButton(200, 1450, 200, 50) 
    field_scene->add(a)
    //b := new MyWidget(..)
 
    ui::MainLoop::refresh()

  def handle_key_event(input::SynKeyEvent &key_ev):
    print "KEY PRESSED", key_ev.key

  def handle_motion_event(input::SynMouseEvent &syn_ev):
    pass

  void game_over(int status):
    gd->show()

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
