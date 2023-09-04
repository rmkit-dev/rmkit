#include "widget.h"
#include "../util/signals.h"

namespace ui:
  // class: ui::Scene
  // --- Prototype ---
  // class ui::InnerScene:
  // -----------------
  //
  // A scene is a collection of widgets that are drawn
  // on screen. The MainLoop can display two scenes at a time,
  // the main scene and the overlay scene (used for dialogs).
  //
  // Generally, you want to add stuff to a scene using a Layout,
  // but if you want to absolutely position your elements, you can
  // directly add them to the scene with add()
  class InnerScene:
    public:
    vector<shared_ptr<Widget>> widgets

    /// variable: pinned
    /// whether scene is pinned (only for overlays)
    bool pinned = false

    /// variable: clear_under
    /// whether scene stops widgets below it from refresh
    bool clear_under = false

    // function: add
    // adds a widget to the scene
    void add(Widget *w):
      widgets.push_back(shared_ptr<Widget>(w))

    // function: add
    // adds a widget to the scene
    void add(shared_ptr<Widget> w):
      widgets.push_back(w)

    static void redraw(vector<shared_ptr<Widget>> &widgets):
      for auto it = widgets.begin(); it != widgets.end(); it++:
        auto &widget = *it
        widget->before_render()
        if !widget->visible:
          continue

        if widget->dirty:
          widget->render()
          widget->render_border()
          widget->dirty = 0

        if widget->children.size():
          redraw(widget->children)

    static void refresh(vector<shared_ptr<Widget>> &widgets):
      for auto &widget: widgets:
        widget->mark_redraw()
        if widget->children.size():
          refresh(widget->children)

    void redraw():
      InnerScene::redraw(widgets)

    void refresh():
      refresh(widgets)

    struct DialogVisible {}
    PLS_DEFINE_SIGNAL(DIALOG_VIS_EVENT, DialogVisible)
    DIALOG_VIS_EVENT on_show;
    DIALOG_VIS_EVENT on_hide;


  typedef shared_ptr<InnerScene> Scene
  static Scene make_scene():
    return make_shared<InnerScene>()
