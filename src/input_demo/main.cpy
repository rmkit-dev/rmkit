#include <cstddef>
#include "../build/rmkit.h"
using namespace std

class GestureWidget : public ui::Widget:
  public:
  int square_x, square_y
  int size = 60
  int drag_x, drag_y
  remarkable_color default_fill = BLACK
  remarkable_color fill = BLACK
  remarkable_color outline = BLACK
  remarkable_color widget_outline = BLACK

  GestureWidget(int x, y, w, h) : ui::Widget(x, y, w, h):
    square_x = w / 2
    square_y = h / 2
    // drag events
    gestures.drag_start += PLS_LAMBDA(auto & ev) {
      debug "DRAG START"
      if ev.is_long_press:
        fill = GRAY
      drag_x = ev.x - square_x
      drag_y = ev.y - square_y
      dirty = 1
    }
    gestures.drag_end += PLS_LAMBDA(auto & ev) {
      debug "DRAG END"
      fill = default_fill
      dirty = 1
    }
    gestures.dragging += PLS_LAMBDA(auto & ev) {
      debug "DRAGGING", ev.x, ev.y
      square_x = max(x+(size/2),min(x+w-(size/2), ev.x - drag_x))
      square_y = max(y+(size/2),min(y+h-(size/2), ev.y - drag_y))
      dirty = 1
    }
    // click events
    gestures.long_press += PLS_LAMBDA(auto & ev) {
      debug "LONG PRESS", ev.x, ev.y
      widget_outline = (widget_outline == BLACK) ? GRAY : BLACK
      dirty = 1
    }
    gestures.single_click += PLS_LAMBDA(auto & ev) {
      debug "SINGLE CLICK", ev.x, ev.y
      default_fill = fill = (fill == BLACK) ? WHITE : BLACK
      dirty = 1
    }
    gestures.double_click += PLS_LAMBDA(auto & ev) {
      debug "DOUBLE CLICK", ev.x, ev.y
      outline = (outline == BLACK) ? GRAY : BLACK
      dirty = 1
    }

  void render():
    // background
    fb->draw_rect(x+10, y+10, w-20, h-20, WHITE, true)
    for i 0 10:
      fb->draw_rect(x+i, y+i, w-2*i, h-2*i, widget_outline, false)
    // drag rect
    cx := x + square_x
    cy := y + square_y
    fb->draw_rect(cx - (size/2),     cy - (size/2),     size,    size,    outline)
    fb->draw_rect(cx - (size/2) + 5, cy - (size/2) + 5, size-10, size-10, fill)

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

    // let's lay out a bunch of stuff

    v_layout := ui::VerticalLayout(0, 0, w, h, demo_scene)
    h_layout1 := ui::HorizontalLayout(0, 0, w, 50, demo_scene)
    h_layout2 := ui::HorizontalLayout(0, 0, w, 50, demo_scene)
    h_layout3 := ui::HorizontalLayout(0, 0, w, 50, demo_scene)

    v_layout.pack_start(h_layout1)
    v_layout.pack_start(h_layout2)
    v_layout.pack_start(h_layout3)

    h_layout1.pack_start(new ui::Text(0, 0, 200, 50, "Héllo world"))
    h_layout2.pack_center(new ui::Text(0, 0, 200, 50, "Hello world"))
    h_layout3.pack_end(new ui::Text(0, 0, 200, 50, "Hello world"))

    // Couple of demo menus
    menu2 := new ui::DropdownMenu(0, 0, 200, 50, "Menu 2")
    menu2->add_section("Hello world")
    menu2->add_options({"Option D", "Option E", "Option F", "Very very very very long option"})
    h_layout1.pack_end(menu2)
    menu2->events.selected += PLS_LAMBDA(int idx):
      debug "MENU 2 SELECTED", idx, menu2->options[idx]->name
    ;

    menu1 := new ui::DropdownMenu(0, 0, 200, 50, "Menu 1")
    menu1->add_options({"Option A", "Option B", "Option C"})
    h_layout1.pack_end(menu1)
    menu1->events.selected += PLS_LAMBDA(int idx):
      debug "MENU 1 SELECTED", idx, menu1->options[idx]->name
    ;

    h_layout := ui::HorizontalLayout(0, 0, w, h, demo_scene)

    v_layout.pack_start(h_layout)
    // showing how an input box works
    h_layout.pack_center(new ui::TextInput(0, 50, 1000, 50))

    range := new ui::RangeInput(0, 150, 1000, 50)
    range->set_range(0, 100)
    h_layout.pack_center(range)


    pager := new ui::Pager(0, 0, 500, 500, NULL)
    pager->options = { "foo", "bar", "baz" }
    pager->setup_for_render()
    pager->events.selected += [=](string t):
      debug "PAGER SELECTED", t
      ui::MainLoop::hide_overlay()

    ;

    btn := new ui::Button(0, 250, 200, 50, "Show Pager")
    btn->mouse.click += [=](input::SynMotionEvent &ev):
      pager->show()
    ;

    h_layout.pack_center(btn)

    text_dropdown := new ui::TextDropdown(0, h-200, 200, 50, "Options")
    text_dropdown->dir = ui::TextDropdown::DIRECTION::UP
    ds := text_dropdown->add_section("options")
    ds->add_options({"foo", "bar", "baz"})

    text_dropdown->events.selected += PLS_LAMBDA(int idx):
      debug "SELECTED", idx, text_dropdown->options[idx]->name
    ;
    h_layout.pack_center(text_dropdown)

    auto drag = new GestureWidget(0, 0, 800, 800)
    v_layout.pack_center(drag)
    h_layout.pack_center(drag)

  def handle_key_event(input::SynKeyEvent &key_ev):
    debug "KEY PRESSED", key_ev.key

  def handle_motion_event(input::SynMotionEvent &syn_ev):
    pass

  def run():

    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)

    // just to kick off the app, we do a full redraw
    ui::MainLoop::refresh()
    ui::MainLoop::redraw()
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


def main():
  App app
  app.run()
