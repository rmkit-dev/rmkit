#include "events.h"
#include "style.h"
#include "../fb/fb.h"
#include "../util/signals.h"

namespace ui:
  // Class: ui::Widget
  //
  // The widget class is the base of all other widgets. A widget is typically
  // a piece of UI that can receive inputs and draw to screen through the
  // frame buffer
  class Widget:
    public:

    // variable: fb
    // every widget has access to fb through self.fb and therefore can (and
    // should) draw directly to the framebuffer
    static framebuffer::FB *fb
    vector<shared_ptr<Widget>> children

    MOUSE_EVENTS mouse
    GESTURE_EVENTS_DELEGATE gestures = { &mouse }
    KEY_EVENTS kbd

    // variables: x, y, w, h
    //
    // x - the x coordinate of the widget.
    // y - the y coordinate of the widget.
    // w - the width of the widget
    // h - the height of the widget
    int x, y, w, h
    int _x, _y, _w, _h // the original values the widget was instantiated with
    int mouse_down = false, mouse_inside = false, mouse_x, mouse_y
    int dirty = 1
    bool visible = true
    string ref // a name to call the widget by
    Style style

    // function: Constructor
    // parameters:
    //
    // x - the x coord of the top left of the widget
    // y - the y coord of the top left of the widget
    // w - the width of the widget
    // h - the height of the widget
    Widget(int x,y,w,h): x(x), y(y), w(w), h(h), _x(x), _y(y), _w(w), _h(h):
      self.install_signal_handlers()

    virtual ~Widget():
      pass

    // function: set_style
    // parameters:
    //
    // style - a ui::Stylesheet or ui::Style
    // Updates the widget's style. Derived classes may override this to copy
    // styles to their children.
    virtual void set_style(const Stylesheet & style):
      style.apply(self.style)

    void operator+=(const Stylesheet & style):
      self.set_style(style)

    // function: mark_redraw
    // marks this widget as needing to be redrawn during the next redraw cycle
    // of the main loop
    virtual void mark_redraw():
      self.dirty = 1

    // function: before_render
    // before_render is called on a widget before it is rendern.
    //
    // this function can be used by a widget query data that it needs to render
    // itself and other ways
    virtual void before_render():
      pass

    // function: render
    // redraws the widget.
    //
    // this function is responsible for rendering the widget to the framebuffer
    // using a combination of draw_line, draw_text and draw_rectangle calls
    virtual void render():
      pass

    // function: render_border
    // redraws the widget border (happens after render())
    virtual void render_border():
      size := 1
      if self.style.border_top:
        self.fb->draw_rect(self.x, self.y, self.w, size, BLACK)
      if self.style.border_bottom:
        self.fb->draw_rect(self.x, self.y + self.h - size, self.w, size, BLACK)
      if self.style.border_left:
        self.fb->draw_rect(self.x, self.y, size, self.h, BLACK)
      if self.style.border_right:
        self.fb->draw_rect(self.x + self.w - size, self.y, size, self.h, BLACK)


    virtual void undraw():
      self.fb->draw_rect(self.x, self.y, self.w, self.h, WHITE, true)

    // function: hide
    // hides the widget
    virtual void hide():
      visible = false

    // function: show
    // shows the widget
    virtual void show():
      visible = true

    // {{{ SIGNAL HANDLERS
    // function: ignore_event
    // this function is called before a widget is given an event
    // and allows the widget to take itself out of the event handling
    // hierarchy by returning true. by removing itself from the hierarchy,
    // event will be handled by other widgets
    virtual bool ignore_event(input::SynMotionEvent &ev):
      return false

    // function: on_mouse_enter
    // called when the motion device enters the widget's bounding box
    virtual void on_mouse_enter(input::SynMotionEvent &ev):
      pass

    // function: on_mouse_leave
    // calls when the motion device leaves the widget's bounding box
    virtual void on_mouse_leave(input::SynMotionEvent &ev):
      pass

    // function: on_mouse_click
    // called when the motion device is activated,
    // either by finger press or stylus press
    virtual void on_mouse_click(input::SynMotionEvent &ev):
      pass

    // function: on_mouse_down
    // called when the mouse is pressed down inside a widget
    virtual void on_mouse_down(input::SynMotionEvent &ev):
      pass

    // function: on_mouse_up
    // called when the mouse is unpressed inside a widget
    virtual void on_mouse_up(input::SynMotionEvent &ev):
      pass

    // function: on_mouse_move
    // called when the mouse is moving inside the widget's
    // area
    virtual void on_mouse_move(input::SynMotionEvent &ev):
      pass

    // function: on_mouse_hover
    // called when the mouse hovers over a widget.
    // this only works with the stylus which can detect
    // hover vs. press events
    virtual void on_mouse_hover(input::SynMotionEvent &ev):
      pass

    // function: on_key_pressed
    /// called when a keyboard key or hardware key is pressed
    virtual void on_key_pressed(input::SynKeyEvent &ev):
      pass

    virtual void install_signal_handlers():
      self.mouse.up += PLS_DELEGATE(on_mouse_up)
      self.mouse.down += PLS_DELEGATE(on_mouse_down)
      self.mouse.move += PLS_DELEGATE(on_mouse_move)
      self.mouse.enter += PLS_DELEGATE(on_mouse_enter)
      self.mouse.leave += PLS_DELEGATE(on_mouse_leave)
      self.mouse.click += PLS_DELEGATE(on_mouse_click)
      self.mouse.hover += PLS_DELEGATE(on_mouse_hover)
      self.kbd.pressed += PLS_DELEGATE(on_key_pressed)

    // }}}

    // checks if this widget is hit by a touch event
    bool is_hit(int o_x, o_y):
      if o_x < x || o_y < y || o_x > x+w || o_y > y+h:
        return false

      return true

    void set_coords(int a=-1, b=-1, c=-1, d=-1):
      if a != -1:
        self.x = a
      if b != -1:
        self.y = b
      if c != -1:
        self.w = c
      if d != -1:
        self.h = d

    // this restores the coordinates of a widget to the coords it was initially
    // given when it was constructed. this could be used to support reflowing
    // widgets
    void restore_coords():
      x = _x
      y = _y
      w = _w
      h = _h

    // function: get_render_size
    // gets the size of the rendered widget. this is for variable sized widgets
    // like text widgets which might have different sizes depending on the
    // supplied text
    virtual tuple<int, int> get_render_size():
      return self.w, self.h


  framebuffer::FB* Widget::fb = NULL
