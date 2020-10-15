// file: main_loop.cpy
//
// Every app usually has a main loop. rmkit's main loop is managed with the
// ui::MainLoop class. In general, an app should look like the following:
//
// --- Code
// // build widgets and place them in scenes
// my_scene = build_scene()
// ui::MainLoop::set_scene(my_scene)
//
// while true:
//   // perform app work, like dispatching events
//   ui::MainLoop::main()
//   // redraw any widgets that marked themselves dirty
//   ui::MainLoop::redraw()
//   // read input (blocking read)
//   ui::MainLoop::read_input()
// ---
//

#include "../defines.h"

#include "../util/signals.h"
#include "../input/input.h"
#include "../fb/fb.h"
#include "scene.h"
#include "widget.h"
#include "task_queue.h"

#include <unistd.h>

namespace ui:
  // class: ui::MainLoop
  // The MainLoop is responsible for rendering widgets, dispatching events, and
  // other core work that happens on each iteration of the app.
  class MainLoop:
    public:
    static shared_ptr<framebuffer::FB> fb

    static Scene scene
    static Scene overlay
    static bool overlay_is_visible

    static Scene kbd
    static bool kbd_is_visible

    static input::Input in

    // variable: motion_event
    // motion_event is used for subscribing to motion_events
    //
    //
    // ---Code
    // // d is of type input::SynMotionEvent
    // MainLoop::motion_event += [=](auto &d) { };
    // ---
    static MOUSE_EVENT motion_event

    // variable: key_event
    // key_event is used for subscribing to key_events
    //
    //
    // ---Code
    // // d is of type input::SynKeyEvent
    // MainLoop::key_event += [=](auto &d) { };
    // ---
    static KEY_EVENT key_event


    class GestureEvent:
      GestureEvent():
        pass

    PLS_DEFINE_SIGNAL(GESTURE_EVENT, GestureEvent)
    // variable: gesture_event
    // gesture_event is used for subscribing to gesture_event
    //
    // ---Code
    // // d is of type input::GestureEvent
    // MainLoop::gesture_event += [=](auto &d) { };
    static GESTURE_EVENT gesture_event

    // returns whether the supplied widget is visible
    static bool is_visible(Widget *w):
      if kbd_is_visible:
        for auto widget : overlay->widgets:
          if widget.get() == w:
            return true
        return false
        
      if overlay_is_visible:
        for auto widget : overlay->widgets:
          if widget.get() == w:
            return true
      for auto widget : scene->widgets:
        if widget.get() == w:
          return true

      return false

    // function: render
    //   sync the framebuffer to the screen, required in order to update
    //   what the screen is showing after any draw calls
    static void redraw():
      fb->redraw_screen()

    // function: check_resize
    // checks if the framebuffer has resized and invokes any callbacks
    static void check_resize():
      fb->check_resize()

    // dispatch input events to their widgets / if event.stop_propagation()
    // was called in the event handler, / then the event will not be handled
    // here.
    static void handle_events():
      for auto ev : in.all_motion_events:
        MainLoop::motion_event(ev)
        if ev._stop_propagation:
          continue
        handle_motion_event(ev)
        fb->last_mouse_ev = ev

      for auto ev : in.all_key_events:
        MainLoop::key_event(ev)
        if ev._stop_propagation:
          continue
        handle_key_event(ev)

    // function: main
    //
    // this function does several thinsg:
    //
    // - dispatches input events to widgets
    // - runs tasks in the task queue
    // - redraws the current scene and overlay's dirty widgets
    static void main():
      handle_events()

      TaskQueue::run_task()

      if kbd_is_visible:
        kbd->redraw()
        return

      scene->redraw()
      if overlay_is_visible:
        overlay->redraw()


    /// blocking read for input
    static void read_input():
      in.listen_all()

    /// queue a render for all the widgets on the visible scenes
    static void refresh():
      scene->refresh()
      if overlay_is_visible:
        overlay->refresh()

    // function: set_scene
    // set the main scene for the app to display when drawing
    static void set_scene(Scene s):
      scene = s

    static void toggle_overlay(Scene s):
      if !overlay_is_visible || s != overlay:
        show_overlay(s)
      else:
        hide_overlay()

    // function: show_overlay
    // set the main scene for the app to display when drawing
    static void show_overlay(Scene s):
      overlay = s
      overlay_is_visible = true
      Widget::fb->clear_screen()
      MainLoop::refresh()
      overlay->on_show()

    // function: hide_overlay
    // hide the overlay
    static void hide_overlay():
      if overlay_is_visible:
        overlay_is_visible = false
        Widget::fb->clear_screen()
        MainLoop::refresh()
        overlay->on_hide()

    static void show_kbd(Scene s):
      kbd = s
      kbd_is_visible = true
      debug "SET KEYBOARD SCENE"
      Widget::fb->clear_screen()
      MainLoop::refresh()
      s->on_show()

    static void hide_kbd():
      if kbd_is_visible:
        kbd_is_visible = false
        Widget::fb->clear_screen()
        MainLoop::refresh()
        kbd->on_hide()


    // clear and refresh the widgets on screen
    // useful if changing scenes or otherwise
    // expecting the whole screen to change
    static void full_refresh():
      Widget::fb->clear_screen()
      MainLoop::refresh()

    // dispatch button presses to their widgets
    static void handle_key_event(input::SynKeyEvent &ev):
      display_scene := scene
      if overlay_is_visible:
        display_scene = overlay

      if kbd_is_visible:
        display_scene = kbd

      for auto widget: display_scene->widgets:
        widget->kbd.pressed(ev)

    // TODO: refactor this into cleaner code
    // dispatch mouse / touch events to their widgets
    static bool handle_motion_event(input::SynMotionEvent &ev):
      display_scene := scene
      if overlay_is_visible:
        display_scene = overlay
      if kbd_is_visible:
        display_scene = kbd

      bool is_hit = false
      bool hit_widget = false
      if ev.x == -1 || ev.y == -1:
        return false

      mouse_down := ev.left || ev.right || ev.middle

      widgets := display_scene->widgets;
      for auto it = widgets.rbegin(); it != widgets.rend(); it++:
        widget := *it
        if widget->ignore_event(ev) || !widget->visible:
          continue

        if ev._stop_propagation:
          break

        is_hit = widget->is_hit(ev.x, ev.y)

        prev_mouse_down := widget->mouse_down
        prev_mouse_inside := widget->mouse_inside
        prev_mouse_x := widget->mouse_x
        prev_mouse_y := widget->mouse_y

        widget->mouse_down = mouse_down && is_hit
        widget->mouse_inside = is_hit

        if is_hit:
          if widget->mouse_down:
            widget->mouse_x = ev.x
            widget->mouse_y = ev.y
            // mouse move issued on is_hit
            widget->mouse.move(ev)
          else:
            // we have mouse_move and mouse_hover
            // hover is for stylus
            widget->mouse.hover(ev)


          // mouse down event
          if !prev_mouse_down && mouse_down:
            widget->mouse.down(ev)

          // mouse up / click events
          if prev_mouse_down && !mouse_down:
            widget->mouse.up(ev)
            widget->mouse.click(ev)

          // mouse enter event
          if !prev_mouse_inside:
            widget->mouse.enter(ev)

          hit_widget = true
        else:
          // mouse leave event
          if prev_mouse_inside:
            widget->mouse.leave(ev)

      if !kbd_is_visible && overlay_is_visible && mouse_down && !hit_widget:
        if !overlay->pinned:
          MainLoop::hide_overlay()

      return hit_widget
  ;

  typedef MainLoop::GestureEvent GestureEvent
  Scene MainLoop::scene = make_scene()
  Scene MainLoop::overlay = make_scene()
  Scene MainLoop::kbd = make_scene()
  bool MainLoop::overlay_is_visible = false
  bool MainLoop::kbd_is_visible = false

  input::Input MainLoop::in = {}

  MOUSE_EVENT MainLoop::motion_event
  KEY_EVENT MainLoop::key_event
  MainLoop::GESTURE_EVENT MainLoop::gesture_event

  shared_ptr<framebuffer::FB> MainLoop::fb = framebuffer::get()

