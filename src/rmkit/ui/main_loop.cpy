#include "../defines.h"

#include "../input/input.h"
#include "scene.h"
#include "base.h"
#include <unistd.h>
#include <functional>

#include <thread>
#include <mutex>

namespace ui:
  class TaskQueue:
    public:
    static deque<std::function<void()>> tasks
    static std::mutex task_m

    static void wakeup():
      _ = write(input::ipc_fd[1], "WAKEUP", sizeof("WAKEUP"));

    static void add_task(std::function<void()> t):
      TaskQueue::tasks.push_back(t)

    static void run_task():
      if TaskQueue::tasks.size() == 0:
        return

      t = TaskQueue::tasks.front()
      TaskQueue::tasks.pop_front()
      try:
        thread *th = new thread([=]() {
          lock_guard<mutex> guard(task_m)
          t()
          TaskQueue::wakeup()
        })
        th->detach()
      catch (const std::exception& e):
        print "NEW THREAD EXC", e.what()
        TaskQueue::wakeup()


  class MainLoop:
    public:
    static Scene scene
    static Scene overlay
    static bool overlay_is_visible

    static bool is_visible(Widget *w):
      if overlay_is_visible:
        for auto widget : overlay->widgets:
          if widget.get() == w:
            return true
      for auto widget : scene->widgets:
        if widget.get() == w:
          return true

      return false


    static void main():
      TaskQueue::run_task()
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
      Widget::fb->clear_screen()
      MainLoop::refresh()

    static void hide_overlay():
      if overlay_is_visible:
        overlay_is_visible = false
        Widget::fb->clear_screen()
        MainLoop::refresh()


    static void full_refresh():
      Widget::fb->clear_screen()
      MainLoop::refresh()

    static void handle_key_event(input::SynKeyEvent &ev):
      display_scene = scene
      if overlay_is_visible:
        display_scene = overlay

      for auto widget: display_scene->widgets:
        widget->on_key_pressed(ev)

    // iterate over all widgets and dispatch mouse events
    // TODO: refactor this into cleaner code
    static bool handle_motion_event(input::SynMouseEvent &ev):
      display_scene = scene
      if overlay_is_visible:
        display_scene = overlay

      bool is_hit = false
      bool hit_widget = false
      if ev.x == -1 || ev.y == -1:
        return false

      mouse_down = ev.left || ev.right || ev.middle

      auto widgets = display_scene->widgets;
      for auto it = widgets.rbegin(); it != widgets.rend(); it++:
        widget = *it
        if widget->ignore_event(ev) || !widget->visible:
          continue

        if ev.stop_propagation:
          break

        is_hit = widget->is_hit(ev.x, ev.y)

        prev_mouse_down = widget->mouse_down
        prev_mouse_inside = widget->mouse_inside
        prev_mouse_x = widget->mouse_x
        prev_mouse_y = widget->mouse_y

        widget->mouse_down = mouse_down && is_hit
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
          if !prev_mouse_down && mouse_down:
            widget->on_mouse_down(ev)

          // mouse up / click events
          if prev_mouse_down && !mouse_down:
            widget->on_mouse_up(ev)
            widget->on_mouse_click(ev)

          // mouse enter event
          if !prev_mouse_inside:
            widget->on_mouse_enter(ev)

          hit_widget = true
        else:
          // mouse leave event
          if prev_mouse_inside:
            widget->on_mouse_leave(ev)

      if overlay_is_visible && mouse_down && !hit_widget:
        MainLoop::hide_overlay()

      return hit_widget
  ;

  Scene MainLoop::scene = make_scene()
  Scene MainLoop::overlay = make_scene()
  bool MainLoop::overlay_is_visible = false

  std::mutex TaskQueue::task_m = {}
  deque<std::function<void()>> TaskQueue::tasks = {}

