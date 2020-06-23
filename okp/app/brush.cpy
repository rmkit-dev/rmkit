#include "../fb/fb.h"
#include "../defines.h"

namespace app_ui:
  typedef int BrushSize

  #ifdef REMARKABLE
  int MULTIPLIER = 1
  #else
  int MULTIPLIER = 4
  #endif

  namespace stroke:
    class Size:
      public:
      BrushSize val
      string name
      const static BrushSize FINE = 0;
      const static BrushSize MEDIUM = 1;
      const static BrushSize WIDE = 2;

      Size(int val, string name): val(val), name(name):
        pass

    static Size FINE   = Size(Size::FINE, "fine")
    static Size MEDIUM = Size(Size::MEDIUM,"medium")
    static Size WIDE   = Size(Size::WIDE, "wide")

    static vector<Size*> SIZES = { &FINE, &MEDIUM, &WIDE }

  struct Point
    int x = 0
    int y = 0
  ;

  class Brush:
    public:

    framebuffer::FB *fb
    int last_x = -1, last_y = -1
    vector<Point> points
    string name = "brush"
    int color = BLACK

    // stroke sizing
    int stroke_width = 1
    BrushSize stroke_val = stroke::Size::MEDIUM
    int sw_thin =  1, sw_medium = 3, sw_thick = 5

    Brush():
      self.set_stroke_width(stroke::Size::MEDIUM)

    ~Brush():
      pass

    inline int get_stroke_width(BrushSize s):
      switch s:
        case stroke::Size::FINE:
          return self.sw_thin
        case stroke::Size::MEDIUM:
          return self.sw_medium
        case stroke::Size::WIDE:
          return self.sw_thick
      return self.sw_thin

    virtual void reset():
      self.points.clear()

    virtual void destroy():
      pass

    virtual void stroke_start(int x, y):
      pass

    virtual void stroke(int x, y, tilt_x, tilt_y, pressure):
      pass

    virtual void stroke_end():
      // TODO return dirty_rect
      pass

    void update_last_pos(int x, int y):
      self.last_x = x
      self.last_y = y
      p = Point{x,y}
      self.points.push_back(p)

    void set_framebuffer(framebuffer::FB *f):
      self.fb = f

    virtual void set_stroke_width(int s):
      self.stroke_val = s
      self.stroke_width = self.get_stroke_width(s)

// {{{ NON PROCEDURAL
  class Charcoal: public Brush:
    public:

    Charcoal(): Brush():
      self.name = "charcoal"

    ~Charcoal():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        s_mod = (abs(tilt_x) + abs(tilt_y)) / 512
        sw = self.stroke_width + s_mod
        dither = pressure / (float(MAX_PRESSURE) * s_mod)
        self.fb->draw_line(self.last_x, self.last_y, x, y, sw, self.color, dither)

    on_stroke_end():
      self.points.clear()

  class Pencil: public Brush:
    public:

    Pencil(): Brush():
      self.name = "pencil"

    ~Pencil():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        s_mod = (abs(tilt_x) + abs(tilt_y)) / 512
        sw = self.stroke_width
        dither = pressure / (float(MAX_PRESSURE/1.5) * s_mod)
        self.fb->draw_line(self.last_x, self.last_y, x, y, sw, self.color, dither)

    on_stroke_end():
      self.points.clear()

  class Marker: public Brush:
    public:

    Marker(): Brush():
      self.name = "marker"

    ~Marker():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        sw = self.stroke_width + (abs(tilt_x) + abs(tilt_y)) / 512
        self.fb->draw_line(self.last_x, self.last_y, x, y, sw, self.color)

    on_stroke_end():
      self.points.clear()

  class BallpointPen: public Brush:
    public:

    BallpointPen(): Brush():
      self.name = "ballpoint"

    ~BallpointPen():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        dither = pressure / float(MAX_PRESSURE) * 1.5
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width, self.color, dither)

  class FineLiner: public Brush:
    public:

    FineLiner(): Brush():
      self.name = "fineliner"

    ~FineLiner():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width, self.color)

    on_stroke_end():
      self.points.clear()

  class PaintBrush: public Brush:
    public:

    PaintBrush(): Brush():
      self.name = "paint brush"
      sw_thin = 15, sw_medium = 25, sw_thick = 50

    ~PaintBrush():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      fpressure = float(max(128, pressure))
      fpressure /= float(4096)
      s_mod = (abs(tilt_x) + abs(tilt_y)) / 512
      sw = int(self.stroke_width * fpressure) + (s_mod * fpressure)
      print "SW", sw, fpressure
      if sw < 1:
        return

      if self.last_x != -1:
        self.fb->draw_line_circle(self.last_x, self.last_y, x, y, sw, self.color)

    on_stroke_end():
      self.points.clear()
// }}}

// {{{ ERASERS
  class Eraser: public Brush:
    public:
    Eraser(): Brush():
      self.name = "eraser"
      sw_thin = 5; sw_medium = 10; sw_thick = 15

    ~Eraser():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width,\
        ERASER_STYLUS)

    void stroke_end():
      Point last_p = Point{-1,-1}
      for auto point: self.points:
        if last_p.x != -1:
          self.fb->draw_line(last_p.x, last_p.y, point.x, point.y, \
          self.stroke_width, WHITE)
        last_p = point
      self.points.clear()

  class RubberEraser: public Brush:
    public:
    RubberEraser(): Brush():
      self.name = "rubber"
      sw_thin = 5; sw_medium = 10; sw_thick = 15

    ~RubberEraser():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width,\
        ERASER_RUBBER)

    void stroke_end():
      Point last_p = Point{-1,-1}
      for auto point: self.points:
        if last_p.x != -1:
          self.fb->draw_line(last_p.x, last_p.y, point.x, point.y, \
          self.stroke_width, WHITE)
        last_p = point
      self.points.clear()
// }}}


// {{{ PROCEDURAL
  class Shaded: public Brush:
    public:
    Shaded(): Brush():
      self.name = "shaded"

    ~Shaded():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      dist = 1000 * MULTIPLIER
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx = point.x - x
        dy = point.y - y
        d = dx * dx + dy * dy
        if d < dist:
          self.fb->draw_line(x,y,point.x,point.y,self.stroke_width,self.color)

  class Sketchy: public Brush:
    public:
    Sketchy(): Brush():
      self.name = "sketchy"

    ~Sketchy():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      dist = 4000 * MULTIPLIER
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx = point.x - x
        dy = point.y - y
        d = dx * dx + dy * dy

        if d < dist && rand() < RAND_MAX / (20 / MULTIPLIER):
          self.fb->draw_line(\
            x + dx * 0.3, \
            y + dy * 0.3, \
            point.x - dx * 0.3, \
            point.y - dy * 0.3, \
            1,self.color)

  class Web: public Brush:
    public:
    Web(): Brush():
      self.name = "web"

    ~Web():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      dist = 5500 * MULTIPLIER
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx = point.x - x
        dy = point.y - y
        d = dx * dx + dy * dy

        if d < dist && rand() < RAND_MAX / (100 / MULTIPLIER):
          self.fb->draw_line(x,y,point.x,point.y,self.stroke_width,self.color)

  class Chrome: public Brush:
    public:
    Chrome(): Brush():
      self.name = "chrome"

    ~Chrome():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      dist = 1000 * MULTIPLIER
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx = point.x - x
        dy = point.y - y
        d = dx * dx + dy * dy

        color = d % 2 == 0 ? GRAY : self.color
        if d < dist && rand() < RAND_MAX / (20 / MULTIPLIER):
          self.fb->draw_line(\
            x + dx * 0.2, \
            y + dy * 0.2, \
            point.x - dx * 0.2, \
            point.y - dy * 0.2, \
            1, color)

  class Fur: public Brush:
    public:
    Fur(): Brush():
      self.name = "fur"

    ~Fur():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      dist = 4000 * MULTIPLIER
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx = point.x - x
        dy = point.y - y
        d = dx * dx + dy * dy

        if d < dist && rand() < RAND_MAX / (20 / MULTIPLIER):
        self.fb->draw_line(x+dx*0.5, y+dy*0.5, x-dx*0.5, y-dy*0.5, \
          self.stroke_width, self.color)

  class LongFur: public Brush:
    public:
    LongFur(): Brush():
      self.name = "long fur"

    ~LongFur():
      pass

    void stroke(int x, y, tilt_x, tilt_y, pressure):
      dist = 4000 * MULTIPLIER
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        size = fast_rand() / FAST_RAND_MAX
        dx = point.x - x
        dy = point.y - y
        d = dx * dx + dy * dy

        if d < dist && rand() < RAND_MAX / (20 / MULTIPLIER):
        self.fb->draw_line(x+dx*size, y+dy*size, x-dx*size, y-dy*size, \
          self.stroke_width, self.color)
// }}}

  namespace brush:
    // PROCEDURAL BRUSHES
    static Brush *FUR           = new Fur()
    static Brush *LONGFUR       = new LongFur()
    static Brush *SHADED        = new Shaded()
    static Brush *SKETCHY       = new Sketchy()
    static Brush *WEB           = new Web()
    static Brush *CHROME        = new Chrome()

    // ERASERS
    static Brush *ERASER        = new Eraser()
    static Brush *RUBBER_ERASER = new RubberEraser()

    // RM STYLE BRUSHES
    static Brush *CHARCOAL        = new Charcoal()
    static Brush *PENCIL          = new Pencil()
    static Brush *MARKER        = new Marker()
    static Brush *BALLPOINT     = new BallpointPen()
    static Brush *FINELINER     = new FineLiner()
    static Brush *PAINTBRUSH    = new PaintBrush()


    static vector<Brush*> NP_BRUSHES = { PENCIL, BALLPOINT, FINELINER, CHARCOAL, MARKER, PAINTBRUSH }
    static vector<Brush*> P_BRUSHES = { SKETCHY, SHADED, CHROME, FUR, LONGFUR, WEB }
    static vector<Brush*> ERASERS = { ERASER, RUBBER_ERASER }
