#include "button.h"
#include "layouts.h"
#include "../input/events.h"

namespace ui:
  class OptionSection: public ui::Button:
    public:
    string text

    OptionSection(int x, y, w, h, string t): ui::Button(x,y,w,h,t):
      self.mouse_inside = true
      self.textWidget->justify = ui::Text::JUSTIFY::CENTER

    bool ignore_event(input::SynMouseEvent &ev):
      return true

  template<typename T>
  class OptionButton: public ui::Button:
    public:
    T* tb
    string text
    int idx

    OptionButton(int x, y, w, h, T* tb, string text, int idx): \
                 tb(tb), text(text), idx(idx), ui::Button(x,y,w,h,text):
      self.x_padding = 10
      self.set_justification(ui::Text::JUSTIFY::LEFT)

    void on_mouse_click(input::SynMouseEvent &ev):
      self.tb->select(self.idx)
      self.dirty = 1

  template<class O>
  class DropdownButton: public ui::Button:
    public:
    int selected
    int option_width, option_height, option_x, option_y
    vector<O> options
    ui::Scene scene = NULL

    DropdownButton(int x, y, w, h, vector<O> options, string name):\
                   options(options), ui::Button(x,y,w,h,name):
      self.select(0)

      self.set_option_offset(0, 0)
      self.set_option_size(w, h)

    void on_mouse_click(input::SynMouseEvent&):
      self.show_options()

    void set_option_offset(int x, y):
      self.option_x = x
      self.option_y = y

    void set_option_size(int width, height):
      self.option_width = width
      self.option_height = height

    void show_options():
      if self.scene == NULL:
        width, height = self.fb->get_display_size()
        ow = self.option_width
        oh = self.option_height

        self.scene = ui::make_scene()
        layout = VerticalLayout(x + self.option_x, self.option_y, ow, height, self.scene)
        i = 0
        for auto option: self.options:
          if option->name.find("===") == 0:
            section = new OptionSection(0, 0, ow, oh, option->name.substr(3))
            layout.pack_end(section)
          else:
            option_btn = new OptionButton<DropdownButton>(0, 0, ow, oh, self, option->name, i)
            if option->icon != NULL:
              option_btn->set_icon(option->icon)
            layout.pack_end(option_btn)
          i++


      ui::MainLoop::show_overlay(self.scene)

    void select(int idx):
      self.selected = idx
      ui::MainLoop::hide_overlay()
      if idx < self.options.size():
        option = self.options[idx]
        self.icon = option->icon
        self.text = self.options[idx]->name

      self.on_select(idx)

    virtual void on_select(int idx):
      pass

  class TextOption:
    public:
    string name
    icons::Icon *icon
    TextOption(string n, icons::Icon *i): name(n), icon(i) {}
    TextOption(string n): name(n) {}


  def make_options(vector<string> options):
    vector<TextOption*> ret
    for auto o: options:
      ret.push_back(new TextOption(o))
    return ret

  class TextDropdown: public ui::DropdownButton<ui::TextOption*>:
    public:
    vector<string> text_options
    TextDropdown(int x, y, w, h, string t): \
      ui::DropdownButton<ui::TextOption*>(x,y,w,h,{},t)
      self.text = t

    void add_section(string t):
        string s = "===" + t
        self.options.push_back(new TextOption(s))

    void add_options(vector<string> opts):
      for auto opt: opts:
        self.options.push_back(new ui::TextOption(opt))

    void add_options(vector<pair<string, icons::Icon*>> pairs):
      for auto pair: pairs:
        opt = pair.first
        icon = pair.second
        textopt = new ui::TextOption(opt, icon)
        self.options.push_back(textopt)
