#include "../build/rmkit.h"
#include "assets.h"

class Piece: public ui::Widget:
  public:
  icons::Icon icon
  int alpha
  Piece(int x, y, w, h): ui::Widget(x, y, w, h):
    pass

  void render():
    pixmap := ui::Pixmap(self.x, self.y, self.w, self.h, self.icon)
    pixmap.alpha = self.alpha
    pixmap.render()

class BlackPiece: public Piece:
  public:
  BlackPiece(int x, y, w, h): Piece(x, y, w, h):
    self.alpha = WHITE

class WhitePiece: public Piece:
  public:
  WhitePiece(int x, y, w, h): Piece(x, y, w, h):
    self.alpha = BLACK

class WhitePawn: public WhitePiece:
  public:
  WhitePawn(int x, y, w, h): WhitePiece(x,y,w,h):
    self.icon = ICON(assets::white_pawn_solid_png)

class BlackPawn: public BlackPiece:
  public:
  BlackPawn(int x, y, w, h): BlackPiece(x,y,w,h):
    self.icon = ICON(assets::black_pawn_solid_png)

class WhiteKnight: public WhitePiece:
  public:
  WhiteKnight(int x, y, w, h): WhitePiece(x,y,w,h):
    self.icon = ICON(assets::white_knight_solid_png)

class BlackKnight: public BlackPiece:
  public:
  BlackKnight(int x, y, w, h): BlackPiece(x,y,w,h):
    self.icon = ICON(assets::black_knight_solid_png)

class WhiteBishop: public WhitePiece:
  public:
  WhiteBishop(int x, y, w, h): WhitePiece(x,y,w,h):
    self.icon = ICON(assets::white_bishop_solid_png)

class BlackBishop: public BlackPiece:
  public:
  BlackBishop(int x, y, w, h): BlackPiece(x,y,w,h):
    self.icon = ICON(assets::black_bishop_solid_png)

class WhiteRook: public WhitePiece:
  public:
  WhiteRook(int x, y, w, h): WhitePiece(x,y,w,h):
    self.icon = ICON(assets::white_rook_solid_png)

class BlackRook: public BlackPiece:
  public:
  BlackRook(int x, y, w, h): BlackPiece(x,y,w,h):
    self.icon = ICON(assets::black_rook_solid_png)

class WhiteQueen: public WhitePiece:
  public:
  WhiteQueen(int x, y, w, h): WhitePiece(x,y,w,h):
    self.icon = ICON(assets::white_queen_solid_png)

class BlackQueen: public BlackPiece:
  public:
  BlackQueen(int x, y, w, h): BlackPiece(x,y,w,h):
    self.icon = ICON(assets::black_queen_solid_png)


class WhiteKing: public WhitePiece:
  public:
  WhiteKing(int x, y, w, h): WhitePiece(x,y,w,h):
    self.icon = ICON(assets::white_king_solid_png)

class BlackKing: public BlackPiece:
  public:
  BlackKing(int x, y, w, h): BlackPiece(x,y,w,h):
    self.icon = ICON(assets::black_king_solid_png)


