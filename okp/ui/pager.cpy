#include "dialog.h"

namespace ui:
  const string PREV = "PREV"
  const string NEXT = "NEXT"
  template<class T>
  class Pager: public ui::Dialog:
    public:
    ui::VerticalLayout *layout
    int page_size, curr_page = 0, opt_h = 50
    vector<string> options
    T *dialog

    Pager(int x, y, w, h, T *d): ui::Dialog(x, y, w, h):
      self.dialog = d
      self.set_title("Select a png file...")
      self.page_size = (self.h - self.opt_h*2) / self.opt_h

    void add_buttons(HorizontalLayout *button_bar):
      if curr_page > 0:
        button_bar->pack_start(new DialogButton<Dialog>(0, 0, 100, 50, self, PREV), 10)
      if curr_page < self.options.size() / self.page_size:
        button_bar->pack_end(new DialogButton<Dialog>(0, 0, 100, 50, self, NEXT), 10)

    void setup_for_render(int page=0):
      if page >= 0 and page <= (self.options.size() / self.page_size):
        self.curr_page = page
      self.scene = ui::make_scene()
      self.contentWidget->x = 0
      self.contentWidget->y = 0
      self.build_dialog()
      self.layout = new ui::VerticalLayout(\
         self.contentWidget->x,\
         self.contentWidget->y,\
         self.contentWidget->w,\
         self.contentWidget->h,\
         self.scene)

      start = self.curr_page*page_size
      end = min(start+page_size, (int)self.options.size())
      for i start end:
        option = self.options[i]
        d = new ui::DialogButton<ui::Dialog>(20,0, self.w-30, self.opt_h, self, option)
        d->set_justification(ui::Text::JUSTIFY::LEFT)
        layout->pack_start(d)


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
        self.dialog->on_row_selected(name)
      ui::MainLoop::refresh()
