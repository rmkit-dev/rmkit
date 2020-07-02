#include "../ui/dialog.h"
#include "../ui/pager.h"
#include <dirent.h>
#include <algorithm>

string ABOUT_TEXT = "\
rmHarmony is a sketching app based on libremarkable and mr. doob's harmony. \
brought to you by the letters N and O. icons are from fontawesome \n\n\
source available at https://github.com/raisjn/rmHarmony \n \
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

  class LoadDialog: public ui::Pager<LoadDialog>:
    public:
      Canvas *canvas

      LoadDialog(int x, y, w, h, Canvas *c): ui::Pager<LoadDialog>(x, y, w, h, self):
        self.canvas = c
        self.set_title("Select a png file...")

      void populate():
        DIR *dir
        struct dirent *ent

        vector<string> filenames
        if ((dir = opendir (SAVE_DIR)) != NULL):
          while ((ent = readdir (dir)) != NULL):
            str_d_name = string(ent->d_name)
            if str_d_name != "." and str_d_name != "..":
              filenames.push_back(str_d_name)
          closedir (dir)
        else:
          perror ("")
        sort(filenames.begin(),filenames.end())
        self.options = filenames

      void on_row_selected(string name):
        self.canvas->load_from_png(name)
        ui::MainLoop::hide_overlay()

