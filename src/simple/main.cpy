#include <cstddef>
#include "../build/rmkit.h"
#include "../shared/string.h"
using namespace std

int FONT_SIZE = ui::Text::DEFAULT_FS
class App:
  public:


  App(ui::Scene s):

    fb := framebuffer::get()
    fb->clear_screen()
    w, h = fb->get_display_size()

    ui::MainLoop::refresh()

  def handle_key_event(input::SynKeyEvent &key_ev):
    pass

  def handle_motion_event(input::SynMouseEvent &syn_ev):
    pass

  def run():
    ui::MainLoop::key_event += PLS_DELEGATE(self.handle_key_event)
    ui::MainLoop::motion_event += PLS_DELEGATE(self.handle_motion_event)
    while true:
      ui::MainLoop::main()
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()


string next_id():
  static int cur_id = 1
  cur_id++
  return string("w") + to_string(cur_id)

ui::Widget* give_id(string id, ui::Widget *w):
  w->ref = id
  return w

int parse_to_int(string s, int line_no):
  int i
  try:
    i = stoi(s)
  catch (const std::invalid_argument& ia):
    cerr << "line " <<  line_no << " : " << s << " cannot be parsed to int"
  return i

def dump_widgets(ui::Scene s):
  for auto widget : s->widgets:
    pass

// directives
int OLD_DEFAULT_FS = ui::Text::DEFAULT_FS
int OLD_DEFAULT_JUSTIFY = ui::Text::DEFAULT_JUSTIFY
def handle_directive(int line_no, ui::Scene s, vector<string> &tokens):
  debug "HANDLING DIRECTIVE", tokens[1]
  if tokens[0] == "@fontsize":
    ui::Text::DEFAULT_FS = stoi(tokens[1])

  if tokens[0] == "@justify":
    if tokens[1] == "left":
      ui::Text::DEFAULT_JUSTIFY = ui::Text::JUSTIFY::LEFT
    if tokens[1] == "center":
      ui::Text::DEFAULT_JUSTIFY = ui::Text::JUSTIFY::CENTER
    if tokens[1] == "right":
      ui::Text::DEFAULT_JUSTIFY = ui::Text::JUSTIFY::RIGHT

WIDTH := 0
HEIGHT := 0
bool handle_widget(int line_no, ui::Scene scene, vector<string> &tokens):
    x := parse_to_int(tokens[1], line_no)
    y := parse_to_int(tokens[2], line_no)

    w := WIDTH
    h := HEIGHT
    if tokens[3] != "w":
      w = parse_to_int(tokens[3], line_no)
    if tokens[4] != "h":
      h = parse_to_int(tokens[4], line_no)

    string t
    for it := tokens.begin() + 5; it != tokens.end(); it++:
      t += *it + " "

    first := tokens[0]
    first_tokens := split(first, ':')
    id := string("")

    ref := false
    if tokens.size() == 2:
      first = tokens[0]
      id = tokens[1]
      ref = true
    else:
      id = next_id()

    if first == "label":
      scene->add(give_id(id, new ui::Text(x,y,w,h,t)))
    else if first == "paragraph":
      scene->add(give_id(id, new ui::MultiText(x,y,w,h,t)))
    else if first == "button":
      button := new ui::Button(x,y,w,h,t)
      widget := give_id(id, button)
      button->set_justification(ui::Text::DEFAULT_JUSTIFY)
      scene->add(widget)
      string v = t
      button->mouse.click += [=](auto &ev):
        dump_widgets(scene)

        if ref:
          print "ref:", button->ref
        else:
          print "selected:", v
        exit(0)
      ;
    else if first == "textinput":
      textinput := give_id(id, new ui::TextInput(x,y,w,h,t))
      scene->add(textinput)
    else if first == "image":
      image := give_id(id, new ui::Thumbnail(x,y,w,h,tokens[5]))
      scene->add(image)
    else:
      return false

    return true

string until_closing_bracket(string line):
  vector<string> lines
  line = line.substr(1)
  // join lines that start / end with []
  do:
    if line[line.length()-1] == ']':
      l := line
      if lines.size():
        l := lines.back()
        lines.pop_back();

      l.resize(l.length()-1)
      lines.push_back(l)
      break

    lines.push_back(line)
  while (getline(cin, line));

  line = ""
  for it := lines.begin(); it != lines.end(); it++:
    line += *it + " "
  return line

def main():
  ui::Scene scene = ui::make_scene()
  ui::MainLoop::set_scene(scene)

  fb := framebuffer::get()
  fb->clear_screen()
  WIDTH, HEIGHT = fb->get_display_size()

  string line
  line_no := 0
  while getline(cin, line):
    line_no += 1

    str_utils::trim(line)


    if line[0] == '[':
      line = until_closing_bracket(line)
    tokens := split(line, ' ')

    first := tokens[0]
    if first[0] == '@':
      handle_directive(line_no, scene, tokens)
      continue

    if tokens.size() < 5:
      cerr << "line " << line_no << ": not enough tokens passed"
      continue

    if !handle_widget(line_no, scene, tokens):
      debug "line ", line_no, ": unknown widget name"
      continue

  app := App(scene)
  app.run()
