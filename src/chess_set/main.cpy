#include <cstddef>
#include "../build/rmkit.h"
#include "assets.h"
using namespace std

PIECE_SIZE := 100

class IBoard:
  public:
  virtual void on_cell_clicked():
    pass

class Piece: public ui::Widget:
  public:
  icons::Icon icon
  Piece(int x, y, w, h): ui::Widget(x, y, w, h):
    pass

  void render():
    pixmap := ui::Pixmap(self.x, self.y, self.w, self.h, self.icon)
    pixmap.render()

class Cell: public ui::Widget:
  public:
  IBoard *board
  Piece *piece = nullptr
  Cell(int x, y, w, h, IBoard *b): ui::Widget(x,y,w,h):
    self.board = b

  void set_piece(Piece *p):
    self.piece = p

  void empty():
    pass // TODO: piece should be null

  void on_mouse_click(input::SynMouseEvent &ev):
    self.board->on_cell_clicked()

  void render():
    self.undraw()
    self.fb->draw_rect(self.x, self.y, self.w, self.h, BLACK, 0)
    if self.piece != nullptr:
      self.piece->render()

class Board: public IBoard, public ui::Widget:
  public:
  vector<vector<Cell*>> grid;
  Board(int x, y, w, h): ui::Widget(x, y, w, h):
    pass

  def make_grid(ui::Scene scene, int n=8):
    c := PIECE_SIZE
    for i := 0; i < n; i++:
      grid.push_back(vector<Cell*>())
      for j := 0; j < n; j++:
        cell := new Cell(i * c, j * c, c, c, self)
        grid[i].push_back(cell)
        scene->add(cell)
    
  void add_piece(int i, j, Piece *p):
    self.grid[i][j]->set_piece(p)

  void move_piece(Piece p):
    pass

  void on_cell_clicked():
    pass


class Bishop: public Piece:
  public:
  Bishop(int x, y, w, h): Piece(x,y,w,h):
    self.icon = ICON(assets::black_bishop_png)

class App:
  public:
  ui::Scene demo_scene


  App():
    demo_scene = ui::make_scene()
    ui::MainLoop::set_scene(demo_scene)

    fb := framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    w, h = fb->get_display_size()

    board := new Board(0, 0, 500, 500)
    board->make_grid(demo_scene)

    // board->move_piece(
    board->add_piece(0, 0, new Bishop(0, 0, PIECE_SIZE, PIECE_SIZE))
    // board->remove_piece(

    demo_scene->add(board)

  def run():
    // just to kick off the app, we do a full redraw
    ui::MainLoop::refresh()
    ui::MainLoop::redraw()
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()

int main():
  App app
  app.run()
