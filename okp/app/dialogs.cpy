#include "../ui/dialog.h"
#include <dirent.h>
#include <algorithm>

string ABOUT_TEXT = "\
rmHarmony is a sketching app based on libremarkable and mr. doob's harmony. \
brought to you by the letters N and O. \n\n source available at https://github.com/raisjn/rmHarmony\
"
namespace app_ui:
  class AboutDialog: public ui::InfoDialog:
    public:
      AboutDialog(int x, y, w, h): ui::InfoDialog(x, y, w, h):
        self.set_title("About")
        self.contentWidget = \
          new ui::MultiText(20, 20, self.w, self.h - 100, ABOUT_TEXT)

  class ExitDialog: public ui::ConfirmationDialog:
    public:
      ExitDialog(int x, y, w, h): ui::ConfirmationDialog(x, y, w, h):
        self.set_title("Exit?")

      void on_button_selected(string t):
        if t == "OK":
          proc::start_xochitl()
          exit(0)
        if t == "CANCEL":
          ui::MainLoop::hide_overlay()

  class SaveDialog: public ui::InfoDialog:
    public:
      SaveDialog(int x, y, w, h): ui::InfoDialog(x, y, w, h):
        pass

  class LoadDialog: public ui::InfoDialog:
    public:
      ui::VerticalLayout *layout
      int page_size, curr_page = 0, opt_h = 50
      Canvas *canvas
      vector<string> filenames

      LoadDialog(int x, y, w, h, Canvas *c): ui::InfoDialog(x, y, w, h):
        self.canvas = c
        self.buttons = {"OK", "PREV", "NEXT"}
        page_size = (self.h - self.opt_h*2) / self.opt_h

      void setup_for_render(int page=0):
        if page >= 0 and page <= (self.filenames.size() / self.page_size):
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
        end = min(start+page_size, (int)self.filenames.size())
        for i start end:
          filename = self.filenames[i]
          layout->pack_start(\
            new ui::DialogButton<ui::Dialog>(\
              5,0, self.w-10, self.opt_h, self,filename))


      void populate():
        DIR *dir
        struct dirent *ent
        if ((dir = opendir (SAVE_DIR)) != NULL):
          while ((ent = readdir (dir)) != NULL):
            str_d_name = string(ent->d_name)
            if str_d_name != "." and str_d_name != "..":
              self.filenames.push_back(str_d_name)
          closedir (dir)
        else:
          perror ("")
        sort(self.filenames.begin(),self.filenames.end())

      void on_button_selected(string name):
        if name == "OK":
          ui::MainLoop::hide_overlay()
        else if name == "PREV":
          self.setup_for_render(self.curr_page-1)
          self.show()
          self.dirty = 1
          ui::MainLoop::refresh()
        else if name == "NEXT":
          self.setup_for_render(self.curr_page+1)
          self.show()
          self.dirty = 1
          ui::MainLoop::refresh()
        else:
          self.canvas->load_from_png(name)
          ui::MainLoop::hide_overlay()
