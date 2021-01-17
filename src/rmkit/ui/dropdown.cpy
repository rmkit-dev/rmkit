#include "button.h"
#include "layouts.h"
#include "../input/events.h"

namespace ui:
  class OptionSection: public ui::Button:
    public:
    string text

    OptionSection(int x, y, w, h, string t): ui::Button(x,y,w,h,t):
      self.mouse_inside = true
      self.style->justify = ui::TextStyle::JUSTIFY::CENTER

    bool ignore_event(input::SynMotionEvent &ev):
      return true

  class IOptionButton:
    public:
    virtual void select(int) = 0

  class OptionButton: public ui::Button:
    public:
    IOptionButton* tb
    string text
    int idx

    OptionButton(int x, y, w, h, IOptionButton* tb, string text, int idx): \
                 tb(tb), text(text), idx(idx), ui::Button(x,y,w,h,text):
      self.x_padding = 10
      self.set_justification(ui::TextStyle::JUSTIFY::LEFT)

    void on_mouse_click(input::SynMotionEvent &ev):
      self.tb->select(self.idx)
      self.dirty = 1

  class IOption:
    public:
    string name
    icons::Icon icon = {NULL, 0}

    IOption():
      pass

    IOption(string name): name(name):
      pass

    IOption(string name, icons::Icon icon): name(name), icon(icon):
      pass

  class TextOption: public IOption:
    public:
    string name
    icons::Icon icon = {NULL, 0}
    TextOption(string n, icons::Icon i): name(n), icon(i) {}
    TextOption(string n): name(n) {}

  class DropdownSection: public IOption:
    public:
    string name
    vector<shared_ptr<IOption>> options
    DropdownSection(string n): name(n):
      pass

    void add_options(vector<string> opts):
      for auto opt: opts:
        self.options.push_back(make_shared<IOption>(opt))

    void add_options(vector<pair<string, icons::Icon>> pairs):
      for auto pair: pairs:
        opt := pair.first
        icon := pair.second
        textopt := make_shared<IOption>(opt, icon)
        self.options.push_back(textopt)

  class DropdownButton: public ui::Button, public IOptionButton:
    public:
    int selected
    int option_width, option_height, option_x, option_y
    enum DIRECTION { UP, DOWN }
    DIRECTION dir = DIRECTION::UP
    vector<shared_ptr<IOption>> options
    vector<shared_ptr<DropdownSection>> sections;
    ui::Scene scene = NULL

    DropdownButton(int x, y, w, h, vector<shared_ptr<IOption>> options, string name):\
                   options(options), ui::Button(x,y,w,h,name):
      self.select(0)

      self.set_option_offset(0, 0)
      self.set_option_size(w, h)

    void on_mouse_click(input::SynMotionEvent&):
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
        ow := self.option_width
        oh := self.option_height
        self.options.clear()

        self.scene = ui::make_scene()
        y_off := self.option_y
        if dir == DIRECTION::DOWN:
          y_off = y - self.option_y
        layout := VerticalLayout(x + self.option_x, y_off, ow, height, self.scene)

        i := 0
        for auto section: self.sections:
          OptionSection *os
          if section->name != "":
            os = new OptionSection(0, 0, ow, oh, section->name)
            if self.dir == DOWN:
              layout.pack_start(os)

          opts := section->options

          for auto option: opts:
            option_btn := new OptionButton(0, 0, ow, oh, self, option->name, i)
            if option->icon.data != NULL:
              option_btn->icon = option->icon

            if self.dir == UP:
              layout.pack_end(option_btn)
            else:
              layout.pack_start(option_btn)
            self.options.push_back(option)
            i++

          if section->name != "":
            if self.dir == UP:
              layout.pack_end(os)



      ui::MainLoop::show_overlay(self.scene)

    void select(int idx):
      self.selected = idx
      ui::MainLoop::hide_overlay()
      if idx < self.options.size():
        option := self.options[idx]
        self.icon = option->icon
        self.text = option->name

        self.on_select(idx)

    virtual void on_select(int idx):
      pass

  // class: ui::TextDropdown
  // --- Prototype ---
  // class ui::TextDropdown: public ui::DropdownButton:
  // ----------------
  // The TextDropdown is the most likely dropdown to use -
  // you supply a list of options and the on_select function
  // will be called when one is selected.
  //
  // ---
  //   dropdown := new TextDropdown(0, 0, 200, 50, "options");
  //   ds := dropdown->add_section("options");
  //   ds->add_options({ "foo", "bar", "baz });
  // ---
  //
  // The dropdown can be set to pop upwards or downwards by setting `dir` on
  // the TextDropdown instance to `DIRECTION::UP` or `DIRECTION::DOWN`
  class TextDropdown: public ui::DropdownButton:
    public:
    // function: TextDropdown
    // x -
    // y -
    // w -
    // h -
    // t - the name of the TextDropdown (used for debugging only)
    TextDropdown(int x, y, w, h, string t): ui::DropdownButton(x,y,w,h,{},t)
      self.text = t

    shared_ptr<DropdownSection> add_section(string t):
        ds := make_shared<DropdownSection>(t)
        self.sections.push_back(ds)
        return ds
