#include <cstddef>
#include "../build/rmkit.h"
using namespace std

class App:
  public:
  ui::Scene scene


  App(ui::Scene s):
    self.scene = s
    ui::MainLoop::set_scene(scene)

    fb := framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    w, h = fb->get_display_size()

    ui::MainLoop::refresh()

  def handle_key_event(input::SynKeyEvent &key_ev):
    print "KEY PRESSED", key_ev.key

  def handle_motion_event(input::SynMouseEvent &syn_ev):
    pass

  def run():
    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


int parse_to_int(string s, int line_no):
  int i
  try:
    i = stoi(s)
  catch (const std::invalid_argument& ia):
    print "line", line_no, ":", s, "cannot be parsed to int"
  return i


def main():
  ui::Scene scene = ui::make_scene()

  string line
  line_no := 0
  while getline(cin, line):
    line_no += 1
    tokens := split(line, ' ')
    first := tokens[0]

    if tokens.size() < 5:
      print "line", line_no, ": not enough tokens passed"

    x := parse_to_int(tokens[1], line_no)
    y := parse_to_int(tokens[2], line_no)
    w := parse_to_int(tokens[3], line_no)
    h := parse_to_int(tokens[4], line_no)
    string t
    for it := tokens.begin() + 5; it != tokens.end(); it++:
      t += *it + " "

    if first == "label":
      scene->add(new ui::Text(x,y,w,h,t))
    else if first == "paragraph":
      scene->add(new ui::MultiText(x,y,w,h,t))
    else if first == "button":
      button := new ui::Button(x,y,w,h,t)
      scene->add(button)
      button->mouse.click += [=](auto &ev):
        print t
      ;
    else if first == "image":
      image := new ui::Thumbnail(x,y,w,h,tokens[5])
      scene->add(image)
    else:
      print "line", line_no, ": unknown widget name"
      exit(1)

  app := App(scene)
  app.run()
