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
#include "../input/gestures.h"
#include "../fb/fb.h"
#include "scene.h"
#include "widget.h"
#include "task_queue.h"
#include "timer.h"
#include "../ui/reflow.h"

#include <unistd.h>

#define CONTAINS(x, s) (std::find(x.begin(), x.end(), s) != x.end())

namespace ui:
  // class: ui::MainLoop
  // The MainLoop is responsible for rendering widgets, dispatching events, and
  // other core work that happens on each iteration of the app.
  PLS_DEFINE_SIGNAL(EXIT_EVENT, int)
  class MainLoop:
    public:

    static shared_ptr<framebuffer::FB> fb = framebuffer::get()

    static Scene scene = make_scene()
    static vector<Scene> scene_stack = {}

    static bool filter_palm_events = false

    static input::Input in = {}
    static vector<input::Gesture*> gestures = {}
    static EXIT_EVENT exit = {}

    static Scene overlay = nullptr


    // variable: motion_event
    // motion_event is used for subscribing to motion_events
    //
    //
    // ---Code
    // // d is of type input::SynMotionEvent
    // MainLoop::motion_event += [=](auto &d) { };
    // ---
    static MOUSE_EVENT motion_event = {}

    // variable: key_event
    // key_event is used for subscribing to key_events
    //
    //
    // ---Code
    // // d is of type input::SynKeyEvent
    // MainLoop::key_event += [=](auto &d) { };
    // ---
    static KEY_EVENT key_event = {}

    private:

    static void add_overlay(Scene s):
      if not CONTAINS(scene_stack, s):
        scene_stack.push_back(s)

    static Scene remove_overlay():
      if scene_stack.size() > 0:
        s := scene_stack.back()
        scene_stack.pop_back()

        return s
      return nullptr

    static Scene remove_overlay(Scene s):
      if s == nullptr:
        return remove_overlay()

      vector<Scene> new_stack
      Scene ret
      for auto sc : scene_stack:
        if sc.get() == s.get():
          ret = sc
        else:
          new_stack.push_back(sc)

      scene_stack = new_stack
      return ret

    public:

    // returns whether the supplied widget is visible
    static bool is_visible(Widget *w):
      for auto widget : scene->widgets:
        if widget.get() == w:
          return true

      for auto scene : scene_stack:
        for auto widget : scene->widgets:
          if widget.get() == w:
            return true

      return false

    // function add_task
    //   add a task to run during the main loop's next iteration
    static void add_task(std::function<void()> t):
      ui::IdleQueue::add_task(t)

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

      for auto ev : in.all_key_events:
        MainLoop::key_event(ev)
        if ev._stop_propagation:
          continue
        handle_key_event(ev)

    static void reset_gestures():
      // lift all fingers
      debug "RESETTING MT GESTURES"
      for i := 0; i < input::TouchEvent::MAX_SLOTS; i++:
        ui::MainLoop::in.touch.prev_ev.slots[i].left = 0

      ui::MainLoop::in.touch.prev_ev.slot = 0

      for auto g : ui::MainLoop::gestures:
        g->reset()

    // we save the touch input until the finger lifts up
    // so we can analyze whether its a gesture or not
    static void handle_gestures():
      if ui::MainLoop::in.wacom.events.size() > 0:
        for auto g : gestures:
          g->reset()

      for auto &ev: ui::MainLoop::in.touch.events:
        if filter_palm_events:
          if ev.is_palm():
            for auto g : gestures:
              g->valid = false

        for auto g : gestures:
          if ev.lifted:
            if g->valid:
              g->finalize()
            g->reset()
          else:
            ev.count_fingers()
            if g->filter(ev):
              if !g->initialized:
                if input::DEBUG_GESTURES:
                  debug "INITIALIZING", ev.x, ev.y, ev.slot
                g->init(ev)
                g->setup(ev)
                g->count++
              else if g->valid:
                g->handle_event(ev)
                g->count++

    static bool has_clear_under():
      for it := scene_stack.rbegin(); it != scene_stack.rend(); it++:
        if (*it)->clear_under:
          return true
      return false

    // function: main
    //
    // this function does several thinsg:
    //
    // - dispatches input events to widgets
    // - runs tasks in the task queue
    // - redraws the current scene and overlay's dirty widgets
    static void main():
      handle_events()
      TimerList::get()->trigger()

      TaskQueue::run_tasks()
      IdleQueue::run_tasks()

      if not has_clear_under():
        scene->redraw()
      if overlay_is_visible():
        for auto s : scene_stack:
          s->redraw()

    static void reflow(Scene s):
      layouts := ReflowLayout::scene_to_layouts.find(s)
      if layouts == ReflowLayout::scene_to_layouts.end():
        return

      for auto w : s->widgets:
        w->restore_coords()

      unordered_map<ReflowLayout*, bool> has_parent;
      for auto l : layouts->second:
        l->restore_coords()
        for auto w : l->children:
          w->restore_coords()
        l->mark_children(has_parent)

      for auto l : layouts->second:
        if has_parent.find(l) == has_parent.end():
          l->reflow()


    /// blocking read for input
    static void read_input(int timeout_ms=0):
      next_timeout_ms := TimerList::get()->next_timeout_ms()
      if timeout_ms > 0 && (next_timeout_ms == 0 || timeout_ms < next_timeout_ms):
          next_timeout_ms = timeout_ms

      in.listen_all(next_timeout_ms)

    /// queue a render for all the widgets on the visible scenes
    static void refresh():
      if not has_clear_under():
        scene->refresh()

      if overlay_is_visible():
        for it := scene_stack.rbegin(); it != scene_stack.rend(); it++:
          s := *it
          s->refresh()
          if s->clear_under:
            break

      reflow(scene)
      for auto &sc : scene_stack:
        reflow(sc)

    // function: set_scene
    // set the main scene for the app to display when drawing
    static void set_scene(Scene s):
      scene = s

    static Scene get_overlay():
      if overlay_is_visible()
        return scene_stack.back()
      return nullptr

    static void toggle_overlay(Scene s):
      if !overlay_is_visible() || s != get_overlay():
        show_overlay(s, true)
      else:
        hide_overlay(s)

    static void replace_overlay(Scene s):
      scene_stack.clear()
      show_overlay(s)


    static inline bool overlay_is_visible():
      return (scene_stack.size() > 0)

    static inline bool overlay_is_visible(Scene s):
      for auto &sc : scene_stack:
        if sc == s:
          return true
      return false


    // function: show_overlay
    // set the main scene for the app to display when drawing
    static void show_overlay(Scene s, bool stack=false):
      if not stack:
        while scene_stack.size():
          hide_overlay(scene_stack.back())

      add_overlay(s)
      Widget::fb->clear_screen()
      MainLoop::refresh()
      s->on_show()
      overlay = s

    // function: hide_overlay
    // hide the overlay
    static Scene hide_overlay(Scene s):
      Widget::fb->clear_screen()

      ol := remove_overlay(s)
      if ol != nullptr:
        ol->on_hide()

      if scene_stack.size():
        ol = scene_stack.back()
      else
        ol = nullptr

      MainLoop::refresh()
      return ol

    // clear and refresh the widgets on screen
    // useful if changing scenes or otherwise
    // expecting the whole screen to change
    static void full_refresh():
      Widget::fb->clear_screen()
      MainLoop::refresh()

    // dispatch button presses to their widgets
    static void handle_key_event(input::SynKeyEvent &ev):
      display_scene := scene
      if overlay_is_visible():
        display_scene = get_overlay()

    // TODO: refactor this into cleaner code
    // dispatch mouse / touch events to their widgets
    static int first_mouse_down = true;

    static bool handle_motion_event(input::SynMotionEvent &ev):
      display_scene := scene
      if overlay_is_visible():
        display_scene = get_overlay()

      bool is_hit = false
      bool hit_widget = false
      if ev.x == -1 || ev.y == -1:
        return false

      mouse_down := ev.left > 0 || ev.right > 0 || ev.middle > 0

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


        widget->mouse_down_first = (first_mouse_down && mouse_down && is_hit) || widget->mouse_down_first
        widget->mouse_down = widget->mouse_down_first && mouse_down && is_hit
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

            if widget->mouse_down_first:
              widget->mouse.click(ev)

          // mouse enter event
          if !prev_mouse_inside:
            widget->mouse.enter(ev)

          hit_widget = true
        else:
          // mouse leave event
          if prev_mouse_inside:
            widget->mouse.leave(ev)

      // iterate over all widgets and register exit events even if we stop
      // propagation. also reset mouse_down_first if mouse_down is false
      for auto it = widgets.rbegin(); it != widgets.rend(); it++:
        widget := *it
        if widget->ignore_event(ev) || !widget->visible:
          continue

        prev_mouse_inside := widget->mouse_inside

        is_hit = widget->is_hit(ev.x, ev.y)
        widget->mouse_down = widget->mouse_down_first && mouse_down && is_hit
        widget->mouse_inside = is_hit

        if !is_hit:
          if prev_mouse_inside:
            widget->mouse.leave(ev)

        if !mouse_down:
          widget->mouse_down_first = false

      if mouse_down:
        first_mouse_down = false
      else:
        first_mouse_down = true


      ol := get_overlay()
      if ol != nullptr && mouse_down && !hit_widget:
        if !ol->pinned:
          MainLoop::hide_overlay(ol)

      return hit_widget
  ;


