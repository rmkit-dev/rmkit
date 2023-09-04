#include "button.h"
#include "layouts.h"
#include "../ui/main_loop.h"
#include "../input/events.h"
#include "../fb/stb_text.h"

namespace ui:
  class OptionSection: public ui::Button:
    public:
    string text

    OptionSection(int x, y, w, h, string t): ui::Button(x,y,w,h,t):
      self.mouse_inside = true

    bool ignore_event(input::SynMotionEvent &ev):
      return true

  class IOptionButton:
    public:
    virtual void select(int) = 0

  class OptionButton: public ui::Button:
    public:
    static Stylesheet DEFAULT_STYLE = Stylesheet().justify_left()

    IOptionButton* tb
    string text
    int idx

    OptionButton(int x, y, w, h, IOptionButton* tb, string text, int idx): \
                 tb(tb), text(text), idx(idx), ui::Button(x,y,w,h,text):
      self.set_style(DEFAULT_STYLE)

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
    int option_x_padding = 10
    int option_y_padding = 10
    bool use_selection_text = true
    enum DIRECTION { UP, DOWN }
    DIRECTION dir = DIRECTION::UP
    vector<shared_ptr<IOption>> options
    vector<shared_ptr<DropdownSection>> sections;
    ui::Scene scene = NULL

    PLS_DEFINE_SIGNAL(DROPDOWN_EVENT, int)
    class DROPDOWN_EVENTS:
      public:
      DROPDOWN_EVENT selected
    ;
    DROPDOWN_EVENTS events

    DropdownButton(int x, int y, int w, int h,
       vector<shared_ptr<IOption>> options, string name=""): \
                   options(options), ui::Button(x,y,w,h,name):
      // install signal handlers first
      self.events.selected += PLS_DELEGATE(self.on_select)

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

    void set_option_padding(int x_padding, y_padding):
      self.option_x_padding = x_padding
      self.option_y_padding = y_padding

    virtual void prepare_options():
      pass

    void show_options():
      if self.scene == NULL:
        self.prepare_options()
        width, height = self.fb->get_display_size()
        ow := self.option_width
        oh := self.option_height
        self.options.clear()

        self.scene = ui::make_scene()
        x_off := std::min(x + self.option_x, fb->display_width - ow)
        y_off := self.option_y
        dropdown_height := height
        if dir == DIRECTION::DOWN:
          y_off = y + self.option_y
        else:
          y_off = 0
          dropdown_height = y - option_y
        layout := VerticalLayout(x_off, y_off, ow, dropdown_height, self.scene)

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
            option_btn->x_padding = self.option_x_padding
            option_btn->y_padding = self.option_y_padding
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



      ui::MainLoop::show_overlay(self.scene, true) // we stack this overlay

    void select(int idx):
      self.selected = idx
      ui::MainLoop::hide_overlay(self.scene)
      if idx < self.options.size():
        if use_selection_text:
          option := self.options[idx]
          self.icon = option->icon
          self.text = option->name
        self.events.selected(idx)

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

    void add_options(vector<string> opts):
      if self.sections.empty():
        self.add_section("");
      self.sections.back()->add_options(opts)

    void autosize_options(int min_w = 0, int min_h = 0):
      max_w := std::max(self.w, min_w)
      max_h := std::max(self.h, min_h)
      style := OptionButton::DEFAULT_STYLE.build()
      font_size := style.font_size
      // y_padding is only used on buttons if they are VALIGN::TOP
      y_padding := style.valign == Style::VALIGN::TOP ? self.option_y_padding : 0
      for auto section: self.sections:
        if section->name != "":
          image := stbtext::get_text_size(section->name, font_size)
          max_w = std::max(max_w, image.w + 2 * self.option_x_padding)
          max_h = std::max(max_h, image.h + y_padding)
        for auto option: section->options:
          image := stbtext::get_text_size(option->name, font_size)
          max_w = std::max(max_w, image.w + 2 * self.option_x_padding)
          max_h = std::max(max_h, image.h + y_padding)
      self.set_option_size(max_w, max_h)

  class DropdownMenu: public TextDropdown:
    public:
    DropdownMenu(int x, y, w, h, string t): TextDropdown(x, y, w, h, t):
      self.use_selection_text = false
      self.dir = DIRECTION::DOWN
      self.set_option_offset(0, self.h);

    void prepare_options():
      self.autosize_options()
