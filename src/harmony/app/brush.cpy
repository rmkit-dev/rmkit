// @nosplit

#include "../assets.h"

#define EFFECT_MODIFIER 32

namespace app_ui:
  typedef int BrushSize

  int MULTIPLIER = 1

  namespace stroke:
    class Size:
      public:
      BrushSize val
      string name
      icons::Icon icon
      const static BrushSize FINE = 0;
      const static BrushSize MEDIUM = 1;
      const static BrushSize WIDE = 2;

      Size(int val, string name, icons::Icon icon): val(val), name(name), icon(icon):
        pass

    static Size FINE   = Size(Size::FINE, "fine", ICON(assets::icons_fa_spider_solid_png))
    static Size MEDIUM = Size(Size::MEDIUM,"medium", ICON(assets::icons_fa_spider_solid_png))
    static Size WIDE = Size(Size::WIDE,"wide", ICON(assets::icons_fa_spider_solid_png))

    static vector<Size*> SIZES = { &FINE, &MEDIUM, &WIDE }

  struct Point
    int x = 0
    int y = 0
    float tilt_x, tilt_y, pressure;
  ;

  class Brush:
    public:

    framebuffer::FB *fb
    int last_x = -1, last_y = -1
    vector<Point> points
    string name = "brush"
    remarkable_color color = BLACK
    icons::Icon icon

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

    void stroke(int x, y, float tilt_x, tilt_y, pressure):
      self._stroke(x,y, tilt_x, tilt_y, pressure)
      self.update_last_pos(x, y, tilt_x, tilt_y, pressure)
    void stroke_start(int x, y, float tilt_x, tilt_y, pressure):
      self._stroke_start(x,y,tilt_x, tilt_y, pressure)
      self.update_last_pos(x, y, tilt_x, tilt_y, pressure)
    void stroke_end():
      self._stroke_end()
      self.update_last_pos(-1, -1, -1, -1, -1)

    virtual void _stroke_start(int x, y, float tilt_x, tilt_y, pressure):
      pass

    virtual void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      pass

    virtual void _stroke_end():
      // TODO return dirty_rect
      pass

    void update_last_pos(int x, int y, float tilt_x, tilt_y, pressure):
      self.last_x = x
      self.last_y = y
      p := Point{x,y,tilt_x,tilt_y,pressure}
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
      self.icon = ICON(assets::icons_fa_mortar_pestle_solid_png)

    ~Charcoal():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        s_mod := (abs(tilt_x) + abs(tilt_y)) * EFFECT_MODIFIER
        sw := self.stroke_width + s_mod
        dither := pressure / 12.0
        self.fb->draw_line(self.last_x, self.last_y, x, y, sw, self.color, dither)

    void _stroke_end():
      self.points.clear()

  class Pencil: public Brush:
    public:

    Pencil(): Brush():
      self.name = "pencil"
      self.icon = ICON(assets::icons_fa_pencil_alt_solid_png)

    ~Pencil():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        s_mod := (abs(tilt_x) + abs(tilt_y)) * EFFECT_MODIFIER
        sw := self.stroke_width
        dither := pressure / (s_mod/1.5)
        self.fb->draw_line(self.last_x, self.last_y, x, y, sw, self.color, dither)

    void _stroke_end():
      self.points.clear()

  class Marker: public Brush:
    public:

    Marker(): Brush():
      self.name = "marker"
      self.icon = ICON(assets::icons_fa_highlighter_solid_png)

    ~Marker():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        sw := self.stroke_width + (abs(tilt_x) + abs(tilt_y)) * EFFECT_MODIFIER
        self.fb->draw_line(self.last_x, self.last_y, x, y, sw, self.color)

    void _stroke_end():
      self.points.clear()

  class BallpointPen: public Brush:
    public:

    BallpointPen(): Brush():
      self.name = "ballpoint"
      self.icon = ICON(assets::icons_fa_pen_solid_png)

    ~BallpointPen():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        s_mod := 4
        sw := self.stroke_width
        dither := pressure * s_mod
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width, self.color, dither)

  class FineLiner: public Brush:
    public:

    FineLiner(): Brush():
      self.name = "fineliner"
      self.icon = ICON(assets::icons_fa_marker_solid_png)

    ~FineLiner():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width, self.color)

    void _stroke_end():
      self.points.clear()

  class PaintBrush: public Brush:
    public:

    PaintBrush(): Brush():
      self.name = "paint brush"
      sw_thin = 15, sw_medium = 25, sw_thick = 50
      self.icon = ICON(assets::icons_fa_paint_brush_solid_png)

    ~PaintBrush():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      fpressure := float(max((float) 0.03, pressure))
      s_mod := (abs(tilt_x) + abs(tilt_y)) * EFFECT_MODIFIER
      sw := int(self.stroke_width * fpressure) + (s_mod * fpressure)
      if sw < 1:
        return

      if self.last_x != -1:
        self.fb->draw_line_circle(self.last_x, self.last_y, x, y, sw, self.color)

    void _stroke_end():
      self.points.clear()
// }}}

// {{{ ERASERS
  class Eraser: public Brush:
    public:
    Eraser(): Brush():
      self.name = "eraser"
      self.icon = ICON(assets::icons_fa_eraser_solid_png)
      sw_thin = 5; sw_medium = 10; sw_thick = 15

    ~Eraser():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, self.stroke_width,\
        ERASER_STYLUS)

    void _stroke_end():
      Point last_p = Point{-1,-1}
      for auto point: self.points:
        if last_p.x != -1:
          self.fb->draw_line(last_p.x, last_p.y, point.x, point.y, \
          self.stroke_width, TRANSPARENT)
        last_p = point
      self.points.clear()

  class RubberEraser: public Brush:
    public:
    RubberEraser(): Brush():
      self.name = "rubber"
      self.icon = ICON(assets::icons_fa_magic_solid_png)
      sw_thin = 15; sw_medium = 25; sw_thick = 50

    ~RubberEraser():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      if self.last_x != -1:
        fpressure := float(max((float) 0.03, pressure))
        s_mod := (abs(tilt_x) + abs(tilt_y)) * EFFECT_MODIFIER
        sw := int(self.stroke_width * fpressure) + (s_mod * fpressure)
        if sw >= 1:
          self.fb->draw_line(self.last_x, self.last_y, x, y, sw, ERASER_RUBBER)

    void _stroke_end():
      Point last_p = Point{-1,-1}
      for auto point: self.points:
        if last_p.x != -1:
          tilt_x := point.tilt_x
          tilt_y := point.tilt_y
          pressure := point.pressure

          fpressure := float(max((float) 0.03, pressure))
          s_mod := (abs(tilt_x) + abs(tilt_y)) * EFFECT_MODIFIER
          sw := int(self.stroke_width * fpressure) + (s_mod * fpressure)
          if sw >= 1:
            self.fb->draw_line(last_p.x, last_p.y, point.x, point.y, sw, TRANSPARENT)
        last_p = point
      self.points.clear()
// }}}


// {{{ PROCEDURAL
  class Shaded: public Brush:
    public:
    Shaded(): Brush():
      self.name = "shaded"
      self.icon = ICON(assets::icons_fa_mask_solid_png)

    ~Shaded():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      dist := 1000 * MULTIPLIER
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx := point.x - x
        dy := point.y - y
        d := dx * dx + dy * dy
        if d < dist:
          self.fb->draw_line(x,y,point.x,point.y,self.stroke_width,self.color)

  class Sketchy: public Brush:
    public:
    Sketchy(): Brush():
      self.name = "sketchy"
      self.icon = ICON(assets::icons_fa_glasses_solid_png)

    ~Sketchy():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      effect_strength := pressure
      dist := 4000 * MULTIPLIER * effect_strength
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx := point.x - x
        dy := point.y - y
        d := dx * dx + dy * dy

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
      self.icon = ICON(assets::icons_fa_spider_solid_png)

    ~Web():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      s_mod := (abs(tilt_x) + abs(tilt_y)) * EFFECT_MODIFIER
      effect_strength := pressure
      dist := 5500 * MULTIPLIER * effect_strength
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx := point.x - x
        dy := point.y - y
        d := dx * dx + dy * dy

        if d < dist && rand() < RAND_MAX / (100 / MULTIPLIER):
          self.fb->draw_line(x,y,point.x,point.y,self.stroke_width,self.color)

  class Chrome: public Brush:
    public:
    Chrome(): Brush():
      self.name = "chrome"
      self.icon = ICON(assets::icons_fa_vr_cardboard_solid_png)

    ~Chrome():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      effect_strength  := pressure
      dist := 2000 * MULTIPLIER * effect_strength
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx := point.x - x
        dy := point.y - y
        d := dx * dx + dy * dy

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
      self.name = "uniform fur"
      self.icon = ICON(assets::icons_fa_cat_solid_png)

    ~Fur():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      effect_strength := pressure
      dist := 4000 * MULTIPLIER * effect_strength

      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        dx := point.x - x
        dy := point.y - y
        d := dx * dx + dy * dy

        if d < dist && rand() < RAND_MAX / (20 / MULTIPLIER):
        self.fb->draw_line(x+dx*0.5, y+dy*0.5, x-dx*0.5, y-dy*0.5, \
          self.stroke_width, self.color)

  class LongFur: public Brush:
    public:
    LongFur(): Brush():
      self.name = "random fur"
      self.icon = ICON(assets::icons_fa_dog_solid_png)

    ~LongFur():
      pass

    void _stroke(int x, y, float tilt_x, tilt_y, pressure):
      effect_strength := pressure
      dist := 4000 * MULTIPLIER * effect_strength
      if self.last_x != -1:
        self.fb->draw_line(self.last_x, self.last_y, x, y, stroke_width, self.color)

      for auto point: self.points:
        size := fast_rand() / FAST_RAND_MAX
        dx := point.x - x
        dy := point.y - y
        d := dx * dx + dy * dy

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
