#include <cstddef>
#include "../build/rmkit.h"
using namespace std

class App:
  public:


  App(ui::Scene s):

    fb := framebuffer::get()
    fb->clear_screen()
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
    cerr << "line " <<  line_no << " : " << s << " cannot be parsed to int"
  return i

def main():
  ui::Scene scene = ui::make_scene()
  ui::MainLoop::set_scene(scene)

  string line
  line_no := 0
  while getline(cin, line):
    line_no += 1

    if line[0] == '[':
      vector<string> lines
      lines.push_back(line.substr(1))
      // join lines that start / end with []
      while getline(cin, line):
        lines.push_back(line)
        if line[line.length()-1] == ']':
          l := lines.back()
          l.resize(lines.back().length()-1)
          lines.pop_back();
          lines.push_back(l)
          break

      line = ""
      for it := lines.begin(); it != lines.end(); it++:
        line += *it + " "
    tokens := split(line, ' ')
    if tokens.size() < 5:
      cerr << "line " << line_no << ": not enough tokens passed"
      continue
    first := tokens[0]


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
        print "selected:", t
        exit(0)
      ;
    else if first == "textinput":
      textinput := new ui::TextInput(x,y,w,h,t)
      scene->add(textinput)
    else if first == "image":
      image := new ui::Thumbnail(x,y,w,h,tokens[5])
      scene->add(image)
    else:
      cerr << "line " << line_no << " : unknown widget name"
      continue
      exit(1)

  app := App(scene)
  app.run()
