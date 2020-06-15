#include "button.h"
#include "layouts.h"

namespace ui:

  template<typename T>
  class OptionButton: public ui::Button:
    public:
    T* tb
    string text
    int idx

    OptionButton(int x, y, w, h, T* tb, string text, int idx): \
                 tb(tb), text(text), idx(idx), ui::Button(x,y,w,h,text):
      pass

    void on_mouse_click(input::SynEvent &ev):
      self.tb->select(self.idx)
      self.dirty = 1

  template<class O>
  class DropdownButton: public ui::Button:
    public:
    int selected
    vector<O> options
    ui::Scene scene = NULL

    DropdownButton(int x, y, w, h, vector<O> options):\
                   options(options), ui::Button(x,y,w,h,"replace_me"):
      self.select(0)

    void on_mouse_click(input::SynEvent&):
      self.show_options()

    void show_options():

      if self.scene == NULL:
        width, height = self.fb->get_display_size()
        self.scene = ui::make_scene()
        // this leaks layout, but i'm fine with it
        layout = VerticalLayout(x, 0, w, height, self.scene)
        i = 0
        for auto option: self.options:
          option_btn = new OptionButton<DropdownButton>(0, 0, w, h, self, option->name, i)
          option_btn->set_justification(ui::Text::JUSTIFY::LEFT)
          layout.pack_end(option_btn)
          i++


      ui::MainLoop::show_overlay(self.scene)

    void select(int idx):
      self.selected = idx
      ui::MainLoop::hide_overlay()
      if idx < self.options.size():
        self.text = self.options[idx]->name

      self.on_select(idx)

    virtual void on_select(int idx):
      pass

  class TextOption:
    public:
    string name
    TextOption(string n): name(n) {}


  def make_options(vector<string> options):
    vector<TextOption*> ret
    for auto o: options:
      ret.push_back(new TextOption(o))
    return ret

  class TextDropdown: public ui::DropdownButton<ui::TextOption*>:
    public:
    vector<string> text_options
    TextDropdown(int x, y, w, h): \
      ui::DropdownButton<ui::TextOption*>(x,y,w,h,{})
      self.text = "..."

    void add_options(vector<string> opts):
      for auto opt: opts:
        self.options.push_back(new ui::TextOption(opt))
