#include "../defines.h"

#include "../input/input.h"
#include "scene.h"

namespace ui:
  class MainLoop:
    public:
    static Scene scene
    static Scene overlay
    static bool overlay_is_visible

    static void main():
      scene->redraw()
      if overlay_is_visible:
        overlay->redraw()

    static void refresh():
      scene->refresh()
      if overlay_is_visible:
        overlay->refresh()

    static void set_scene(Scene s):
      scene = s

    static void toggle_overlay(Scene s):
      if !overlay_is_visible || s != overlay:
        show_overlay(s)
      else:
        hide_overlay()

    static void show_overlay(Scene s):
      overlay = s
      overlay_is_visible = true
      MainLoop::refresh()

    static void hide_overlay():
      overlay_is_visible = false
      Widget::fb->clear_screen()
      MainLoop::refresh()


    // iterate over all widgets and dispatch mouse events
    // TODO: refactor this into cleaner code
    static bool handle_motion_event(input::SynEvent &ev):
      display_scene = scene
      if overlay_is_visible:
        display_scene = overlay

      bool is_hit = false
      bool hit_widget = false
      if ev.x == -1 || ev.y == -1:
        return false

      for auto widget: display_scene->widgets:
        if widget->ignore_event(ev):
          continue

        is_hit = widget->is_hit(ev.x, ev.y)

        prev_mouse_down = widget->mouse_down
        prev_mouse_inside = widget->mouse_inside
        prev_mouse_x = widget->mouse_x
        prev_mouse_y = widget->mouse_y

        widget->mouse_down = ev.left && is_hit
        widget->mouse_inside = is_hit

        if is_hit:
          if widget->mouse_down:
            widget->mouse_x = ev.x
            widget->mouse_y = ev.y
            // mouse move issued on is_hit
            widget->on_mouse_move(ev)
          else:
            // we have mouse_move and mouse_hover
            // hover is for stylus
            widget->on_mouse_hover(ev)


          // mouse down event
          if !prev_mouse_down && ev.left:
            widget->on_mouse_down(ev)

          // mouse up / click events
          if prev_mouse_down && !ev.left::
            widget->on_mouse_up(ev)
            widget->on_mouse_click(ev)

          // mouse enter event
          if !prev_mouse_inside:
            widget->on_mouse_enter(ev)

          hit_widget = true
          break
        else:
          // mouse leave event
          if prev_mouse_inside:
            widget->on_mouse_leave(ev)


      return hit_widget

  Scene MainLoop::scene = make_scene()
  Scene MainLoop::overlay = make_scene()
  bool MainLoop::overlay_is_visible = false

