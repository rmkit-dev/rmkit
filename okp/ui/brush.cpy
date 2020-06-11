#include "../fb/fb.h"
#include "../defines.h"

namespace ui:
  struct Point
    int x
    int y

  class Brush:
    public:
    framebuffer::FB *fb
    int last_x = -1, last_y = -1
    int stroke_width
    vector<Point> points
    string name = "brush"

    Brush(int stroke_width): stroke_width(stroke_width):
      pass

    ~Brush():
      pass

    virtual void reset():
      self.points.clear()

    virtual void destroy(): 
      pass

    virtual void stroke_start(int x, y):
      pass

    virtual void stroke(int x, y):
      pass

    virtual void stroke_end():
      // TODO return dirty_rect 
      pass

    void update_last_pos(int x, int y):
      self.last_x = x
      self.last_y = y
      self.points.push_back(Point{x,y})

    void set_framebuffer(framebuffer::FB *f):
      self.fb = f


  class Pencil: public Brush:
    public:

    Pencil(int stroke_width): Brush(stroke_width):
      self.name = "pencil"

    ~Pencil():
      pass

    void destroy(): 
      pass

    void stroke_start(int x, y):
      pass

    void stroke(int x, y):
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width, BLACK)

    void stroke_end():
      self.points.clear()

  class Eraser: public Brush:
    public:
    Eraser(int stroke_width): Brush(stroke_width):
      self.name = "eraser"
      pass

    ~Eraser():
      pass

    void destroy(): 
      pass

    void stroke_start(int x, y):
      pass

    void stroke(int x, y):
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width,\
                           ERASER_RUBBER)

    void stroke_end():
      Point last_p = Point{-1,-1}
      for auto point: self.points:
        if last_p.x != -1:
          self.fb->draw_line(last_p.x, last_p.y, point.x, point.y, self.stroke_width,\
                           WHITE)
        last_p = point
      self.points.clear()


  class Shaded: public Brush:
    public:

    Shaded(int stroke_width): Brush(stroke_width):
      self.name = "shaded"

    ~Shaded():
      pass

    void destroy(): 
      pass

    void stroke_start(int x, y):
      pass

    void stroke(int x, y):
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width,\
                           BLACK)

      for auto point: self.points:
        dx = point.x - x
        dy = point.y - y
        d = dx * dx + dy * dy
        if d < 1000:
          self.fb->draw_line(x,y,point.x,point.y,self.stroke_width,BLACK)

    void stroke_end():
      pass
