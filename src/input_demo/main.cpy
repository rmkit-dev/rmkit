#include <cstddef>
#include "../build/rmkit.h"
using namespace std

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

    v_layout.pack_start(h_layout1, 30)
    v_layout.pack_start(h_layout2, 30)
    v_layout.pack_start(h_layout3, 30)

    h_layout1.pack_start(new ui::Text(0, 0, 200, 50, "Héllo world"))
    h_layout2.pack_center(new ui::Text(0, 0, 200, 50, "Hello world"))
    h_layout3.pack_end(new ui::Text(0, 0, 200, 50, "Hello world"))

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
