#include <cstddef>
#include "../build/rmkit.h"
#include "../shared/string.h"
#include "canvas.h"
using namespace std

WIDTH := 0
HEIGHT := 0
EXPECTING_INPUT := false
CLEAR_SCREEN := true
TIMEOUT := 0

extern bool DEBUG_OUTPUT = (getenv("DEBUG") != NULL)

map<string, SimpleCanvas*> canvases
void on_exit(int s):
  for auto it : canvases:
    name := it.first
    canvas := it.second
    canvas->vfb->save_lodepng(name, 0, 0, canvas->w, canvas->h)

def do_exit(int s):
  on_exit(s)
  exit(s)

class App:
  public:


  App(ui::Scene s):

    fb := framebuffer::get()
    w, h = fb->get_display_size()

    ui::MainLoop::refresh()

  def handle_key_event(input::SynKeyEvent &key_ev):
    pass

  def handle_motion_event(input::SynMotionEvent &syn_ev):
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

// directives
ui::Style OLD_DEFAULT_STYLE = ui::Style::DEFAULT
int PADDING_X = 0
int PADDING_Y = 0
def handle_directive(int line_no, ui::Scene s, vector<string> &tokens):
  if DEBUG_OUTPUT:
    debug "HANDLING DIRECTIVE", tokens[0], tokens[1]
  if tokens[0] == "@fontsize":
    ui::Style::DEFAULT.font_size = stoi(tokens[1])

  if tokens[0] == "@noclear":
    CLEAR_SCREEN = false

  if tokens[0] == "@justify":
    if tokens[1] == "left":
      ui::Style::DEFAULT.justify = ui::Style::JUSTIFY::LEFT
    if tokens[1] == "center":
      ui::Style::DEFAULT.justify = ui::Style::JUSTIFY::CENTER
    if tokens[1] == "right":
      ui::Style::DEFAULT.justify = ui::Style::JUSTIFY::RIGHT

  if tokens[0] == "@padding_x":
    PADDING_X = parse_to_int(tokens[1], line_no, WIDTH)
  if tokens[0] == "@padding_y":
    PADDING_Y = parse_to_int(tokens[1], line_no, HEIGHT)

  if tokens[0] == "@timeout":
    TIMEOUT = max(TIMEOUT, stoi(tokens[1]))


auto parse_int_token(string value, int line_no, size):
  tokens := str_utils::split(value, '+')
  if tokens.size() == 2:
    return tokens[0], parse_to_int(tokens[1], line_no, size)
  tokens = str_utils::split(value, '-')
  if tokens.size() == 2:
    return tokens[0], -parse_to_int(tokens[1], line_no, size)

  return value, 0


auto parse_widget(int line_no, vector<string> tokens):
  x_token, x_padding := parse_int_token(tokens[1], line_no, WIDTH)
  y_token, y_padding := parse_int_token(tokens[2], line_no, HEIGHT)
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
  if x_token == "next" or x_token == "same" or x_token == "step" or x_token == "stay":
    if LAST_WIDGET == NULL:
      x = 0 + PADDING_X
    else:
      if x_token == "next" or x_token == "step":
        rx, ry = LAST_WIDGET->get_render_size()
        x = LAST_WIDGET->x + rx
      if x_token == "same" or x_token == "stay":
        x = LAST_WIDGET->x
  else:
    x = parse_to_int(x_token, line_no, WIDTH) + PADDING_X
  if x > WIDTH:
    x = WIDTH

  if y_token == "next" or y_token == "same" or y_token == "step" or y_token == "stay":
    if LAST_WIDGET == NULL:
      y = 0 + PADDING_Y
    else:
      if y_token == "next" or y_token == "step":
        rx, ry = LAST_WIDGET->get_render_size()
        y = LAST_WIDGET->y + ry
      if y_token == "same" or y_token == "stay":
        y = LAST_WIDGET->y
  else:
    y = parse_to_int(y_token, line_no, HEIGHT) + PADDING_Y
  if y > HEIGHT:
    y = HEIGHT

  string t
  for it := tokens.begin() + 5; it != tokens.end(); it++:
    t += *it + " "
  str_utils::rtrim(t)

  return x+x_padding, y+y_padding, w, h, t


bool handle_widget(int line_no, ui::Scene scene, vector<string> &tokens):
    first := tokens[0]
    first_tokens := str_utils::split(first, ':')
    id := string("")

    x,y,w,h,t := parse_widget(line_no, tokens)

    ref := false
    if first_tokens.size() == 2:
      first = first_tokens[0]
      id = first_tokens[1]
      if DEBUG_OUTPUT:
        debug "SETTING ID TO", id
      ref = true
    else:
      id = next_id()

    if first == "label":
      scene->add(give_id(id, new ui::Text(x,y,w,h,t)))
    else if first == "paragraph":
      scene->add(give_id(id, new ui::MultiText(x,y,w,h,t)))
    else if first == "button":
      EXPECTING_INPUT = true
      button := new ui::Button(x,y,w,h,t)
      widget := give_id(id, button)
      button->set_style(ui::Stylesheet().justify(ui::Style::DEFAULT).underline(true))
      scene->add(widget)
      string v = t
      button->mouse.click += [=](auto &ev):
        if ref:
          print "selected:", button->ref
        else:
          print "selected:", v
        do_exit(0)
      ;
    else if first == "textinput":
      EXPECTING_INPUT = true
      textinput := new ui::TextInput(x,y,w,h,t)
      textinput->set_style(ui::Stylesheet().justify(ui::Style::DEFAULT).valign(ui::Style::VALIGN::MIDDLE))
      textinput->events.done += PLS_LAMBDA(string &s):
        if DEBUG_OUTPUT:
          debug "PRINTING REF", t, textinput->ref,  s
        if ref:
          print "input:", textinput->ref, ":", s
        else:
          print "input:", t, ":", s
        do_exit(0)
      ;
      widget := give_id(id, textinput)
      scene->add(widget)
    else if first == "textarea":
      EXPECTING_INPUT = true
      textinput := new ui::TextArea(x,y,w,h,t)
      textinput->events.done += PLS_LAMBDA(string &s):
        if DEBUG_OUTPUT:
          debug "PRINTING REF", t, textinput->ref,  s
        if ref:
          print "input:", textinput->ref, ":", s
        else:
          print "input:", t, ":", s
        do_exit(0)
      ;
      widget := give_id(id, textinput)
      scene->add(widget)
    else if first == "range"
      EXPECTING_INPUT = true
      range := new ui::RangeInput(x,y,w,h)
      toks := str_utils::split(t, ' ')
      if len(toks) != 3:
        debug "ERROR: range format is x y w h low high value"
      else:
        int l, h, v
        try
          l = stoi(toks[0])
          h = stoi(toks[1])
          v = stoi(toks[2])
        catch (const std::invalid_argument& ia):
          debug "ERROR: range format is x y w h low high value"
          return true

        range->set_range(l, h)
        range->set_value(v)
        range->set_style(ui::Stylesheet().justify(ui::Style::DEFAULT).valign(ui::Style::VALIGN::MIDDLE))
        widget := give_id(id, range)
        range->events.done += PLS_LAMBDA(auto &s):
          if DEBUG_OUTPUT:
            debug "PRINTING REF", t, range->ref,  range->get_value()
          print "range:", range->ref, ":", range->get_value()
          do_exit(0)
        ;
        scene->add(widget)
    else if first == "image":
      image := give_id(id, new ui::Thumbnail(x,y,w,h,tokens[5]))
      scene->add(image)
      string v = t

      if ref:
        EXPECTING_INPUT = true

      image->mouse.click += [=](auto &ev):
        if ref:
          print "selected:", image->ref
          do_exit(0)
      ;
    else if first == "canvas":
      if len(tokens) < 6 || len(tokens) > 7:
        debug "Invalid format for canvas, expected: canvas x y w h rawfile [pngfile]"
      else:
        c := new SimpleCanvas(x,y,w,h,tokens[5])
        if len(tokens) > 6:
          save_as := tokens[6]
          canvases[save_as] = c
        canvas := give_id(id, c)
        scene->add(canvas)
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
    line += *it + " \n"
  return line

def main():
  ui::Scene scene = ui::make_scene()
  ui::MainLoop::set_scene(scene)
  ui::MainLoop::exit += [=](int s) {
    on_exit(s)
  };

  fb := framebuffer::get()
  WIDTH, HEIGHT = fb->get_display_size()

  string line
  line_no := 0
  while getline(cin, line):
    line_no += 1

    str_utils::trim(line)

    if line == "":
      continue

    if line[0] == '[':
      line = until_closing_bracket(line)
    tokens := str_utils::split(line, ' ')

    first := tokens[0]
    if first[0] == '@':
      handle_directive(line_no, scene, tokens)
      continue

    if tokens.size() < 5:
      cerr << "line " << line_no << ": not enough tokens passed" << endl
      continue

    if !handle_widget(line_no, scene, tokens):
      debug "line ", line_no, ": unknown widget name"
      continue

  if TIMEOUT > 0:
    thread *th = new thread([=]() {
      sleep(TIMEOUT)
      print "timeout:", TIMEOUT
      do_exit(0)
    })
    th->detach()

  if CLEAR_SCREEN:
    fb->clear_screen()

  app := App(scene)
  app.run()
