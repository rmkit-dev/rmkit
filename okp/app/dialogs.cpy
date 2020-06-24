#include "../ui/dialog.h"

string ABOUT_TEXT = "\
rmHarmony is a sketching app based on libremarkable and mr. doob's harmony. \
brought to you by the letters N and O. \n\n source available at https://github.com/raisjn/rmHarmony\
"
namespace app_ui:
  class AboutDialog: public ui::InfoDialog:
    public:
      AboutDialog(int x, y, w, h): ui::InfoDialog(x, y, w, h):
        self.set_title("About")
        self.set_content(ABOUT_TEXT)

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
