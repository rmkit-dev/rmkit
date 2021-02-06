#include "dialog.h"
#include "thumbnail.h"

namespace ui:
  const string PREV = "PREV"
  const string NEXT = "NEXT"
  class IPager:
    public:
    virtual void on_row_selected(string t):
      return

  // class: ui::Pager
  // --- Prototype ---
  // class ui::Pager: public ui::Dialog, public ui::IPager:
  // -----------------
  // a Pager is a modal dialog that lets one browse through
  // multiple pages of results using a next and previous button.
  class Pager: public ui::Dialog, public IPager:
    public:
    shared_ptr<ui::VerticalLayout> layout
    int page_size, curr_page = 0, opt_h = 50
    vector<string> options
    IPager *dialog

    PLS_DEFINE_SIGNAL(PAGER_EVENT, string)
    class PAGER_EVENTS:
      public:
      PAGER_EVENT selected;
    ;
    PAGER_EVENTS events

    Pager(int x, y, w, h, IPager *d=NULL): ui::Dialog(x, y, w, h):
      self.dialog = d
      self.page_size = self.h / self.opt_h - 1

    void add_buttons(HorizontalLayout *button_bar):
      if curr_page > 0:
        button_bar->pack_start(new DialogButton(1, 0, 100, 50, self, PREV))
      if (curr_page+1) * self.page_size < self.options.size():
        button_bar->pack_end(new DialogButton(-1, 0, 100, 50, self, NEXT))

    virtual void render_row(ui::HorizontalLayout *row, string option):
      d := new ui::DialogButton(20,0, self.w-80, self.opt_h, self, option)
      d->set_style(Stylesheet().justify_left())
      layout->pack_start(d)

    void setup_for_render(int page=0):
      if page >= 0 and page <= (self.options.size() / self.page_size):
        self.curr_page = page
      self.scene = ui::make_scene()
      self.scene->on_hide = self.on_hide
      self.titleWidget->restore_coords()
      self.contentWidget->restore_coords()
      self.build_dialog()
      self.layout = make_shared<ui::VerticalLayout>(\
         self.contentWidget->x,\
         self.contentWidget->y,\
         self.contentWidget->w,\
         self.contentWidget->h,\
         self.scene)

      start := self.curr_page*page_size
      end := min(start+page_size, (int)self.options.size())
      for i start end:
        ui::HorizontalLayout *row = new ui::HorizontalLayout(
          0,
          0,
          self.contentWidget->w-40,
          self.opt_h,
          self.scene)
        option := self.options[i]

        self.render_row(row, option)

    virtual void populate():
      pass

    void on_button_selected(string name):
      if name == PREV:
        self.setup_for_render(self.curr_page-1)
        self.show()
      else if name == NEXT:
        self.setup_for_render(self.curr_page+1)
        self.show()
      else:
        if self.dialog != NULL:
          self.dialog->on_row_selected(name)
        self.events.selected(name)

      ui::MainLoop::refresh()
