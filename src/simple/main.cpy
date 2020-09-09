#include <cstddef>
#include "../build/rmkit.h"
#include "../shared/string.h"
using namespace std

int FONT_SIZE = ui::Text::DEFAULT_FS
WIDTH := 0
HEIGHT := 0
EXPECTING_INPUT := false
TIMEOUT := 0
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

      if !EXPECTING_INPUT && !TIMEOUT:
        break


string next_id():
  static int cur_id = 1
  cur_id++
  return string("w") + to_string(cur_id)

ui::Widget *LAST_WIDGET = NULL
ui::Widget* give_id(string id, ui::Widget *w):
  w->ref = id
  LAST_WIDGET = w
  return w

int parse_to_int(string s, int line_no, max_val):
  int i

  if s.find(string("%"), 0) != string::npos:
    s.resize(s.size() - 1)
    i = stoi(s)
    percent := i / 100.0
    return int(percent * max_val)

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
int PADDING_X = 0
int PADDING_Y = 0
def handle_directive(int line_no, ui::Scene s, vector<string> &tokens):
  debug "HANDLING DIRECTIVE", tokens[0], tokens[1]
  if tokens[0] == "@fontsize":
    ui::Text::DEFAULT_FS = stoi(tokens[1])

  if tokens[0] == "@justify":
    if tokens[1] == "left":
      ui::Text::DEFAULT_JUSTIFY = ui::Text::JUSTIFY::LEFT
    if tokens[1] == "center":
      ui::Text::DEFAULT_JUSTIFY = ui::Text::JUSTIFY::CENTER
    if tokens[1] == "right":
      ui::Text::DEFAULT_JUSTIFY = ui::Text::JUSTIFY::RIGHT

  if tokens[0] == "@padding_x":
    PADDING_X = stoi(tokens[1])
  if tokens[0] == "@padding_y":
    PADDING_Y = stoi(tokens[1])

  if tokens[0] == "@timeout":
    TIMEOUT = max(TIMEOUT, stoi(tokens[1]))


auto parse_widget(int line_no, vector<string> tokens):
  x_token := tokens[1]
  y_token := tokens[2]
  w_token := tokens[3]
  h_token := tokens[4]
  x := 0
  y := 0

  // for x and y, there are two keywords: "next" and "same"
  // which increment the field by LAST_WIDGET's x or y

  // for w, h, we have "w" and "h" as keywords, but i think
  // "full" might make more sense (instead of using w vs h)
  w := WIDTH
  h := HEIGHT
  if w_token != "w":
    w = parse_to_int(w_token, line_no, WIDTH)
  if h_token != "h":
    h = parse_to_int(h_token, line_no, HEIGHT)

  // TODO: add "%" format
  // TODO: % format might also need to be implemented for padding?
  if x_token == "next" or x_token == "same" or x_token == "step":
    if LAST_WIDGET == NULL:
      x = 0
    else:
      if x_token == "next" or x_token == "step":
        rx, ry = LAST_WIDGET->get_render_size()
        x = LAST_WIDGET->x + rx
      if x_token == "same":
        x = LAST_WIDGET->x

  else:
    x = parse_to_int(x_token, line_no, WIDTH)

  if y_token == "next" or y_token == "same" or y_token == "step":
    if LAST_WIDGET == NULL:
      y = 0
    else:
      if y_token == "next" || y_token == "step":
        rx, ry = LAST_WIDGET->get_render_size()
        y = LAST_WIDGET->y + ry
      if y_token == "same":
        y = LAST_WIDGET->y
  else:
    y = parse_to_int(y_token, line_no, HEIGHT)

  string t
  for it := tokens.begin() + 5; it != tokens.end(); it++:
    t += *it + " "

  return x, y, w, h, t


bool handle_widget(int line_no, ui::Scene scene, vector<string> &tokens):
    first := tokens[0]
    first_tokens := split(first, ':')
    id := string("")

    x,y,w,h,t := parse_widget(line_no, tokens)

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
      EXPECTING_INPUT = true
      string v = t
      button->mouse.click += [=](auto &ev):
        dump_widgets(scene)

        if ref:
          print "selected:", button->ref
        else:
          print "selected:", v
        exit(0)
      ;
    else if first == "textinput":
      textinput := new ui::TextInput(x,y,w,h,t)
      textinput->events.done += PLS_LAMBDA(string &s):
        debug "PRINTING REF", t, textinput->ref,  s
        if ref:
          print "input:", textinput->ref, ":", s
        else:
          print "input:", t, ":", s
        exit(0)
      ;
      widget := give_id(id, textinput)
      scene->add(widget)
    else if first == "textarea":
      textinput := new ui::TextArea(x,y,w,h,t)
      textinput->events.done += PLS_LAMBDA(string &s):
        debug "PRINTING REF", t, textinput->ref,  s
        if ref:
          print "input:", textinput->ref, ":", s
        else:
          print "input:", t, ":", s
        exit(0)
      ;
      widget := give_id(id, textinput)
      scene->add(widget)
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
  str_utils::trim(line)
  if line[line.length()-1] == ']':
    return line.substr(0, line.length()-1)

  do:
    if line[line.length()-1] == ']':
      l := line

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

  if TIMEOUT > 0:
    ui::TaskQueue::add_task([=]() {
      sleep(TIMEOUT)
      print "timeout:", TIMEOUT
      exit(0)
    });

  app := App(scene)
  app.run()
