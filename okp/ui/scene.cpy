#include "base.h" 

namespace ui: 
  class InnerScene:
    public:
    vector<shared_ptr<Widget>> widgets

    void add(Widget *w):
      widgets.push_back(shared_ptr<Widget>(w))

    void redraw():
      for auto &widget: widgets:
        if widget->dirty:
          widget->redraw()
          widget->dirty = 0

    void refresh():
      for auto &widget: widgets:
        widget->dirty = 1

  typedef shared_ptr<InnerScene> Scene
  static Scene make_scene():
    return make_shared<InnerScene>()

