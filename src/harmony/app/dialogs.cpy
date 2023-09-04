#include <algorithm>

#define DIALOG_WIDTH 600
#define DIALOG_HEIGHT 500
#define LOAD_DIALOG_HEIGHT 1000

string ABOUT_TEXT = "\
rmHarmony is a sketching app based on libremarkable and mr. doob's harmony. \
brought to you by the letters N and O. icons are from fontawesome \n\n\
source available at https://github.com/rmkit-dev/rmKit \n \
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
          exit(0)
        if t == "CANCEL":
          self.hide()

  class ExportDialog: public ui::InfoDialog:
    public:
      ExportDialog(int x, y, w, h): ui::InfoDialog(x, y, w, h):
        pass

  class SaveProjectDialog: public ui::ConfirmationDialog:
    public:
      Canvas *canvas
      ui::TextInput *projectInput
      SaveProjectDialog(int x, y, w, h, Canvas *c): ui::ConfirmationDialog(x, y, w, h):
        canvas = c
        self.set_title("Save project as")
        style := ui::Stylesheet().justify_left().valign_middle()
        self.projectInput = \
          new ui::TextInput(20, 20, self.w - 40, 50, "")
        self.projectInput->set_style(style)
        self.contentWidget = self.projectInput
        self.projectInput->events.done += PLS_LAMBDA(string text):
          self.mark_redraw()
          canvas->set_project_name(text)
        ;

      void before_render():
        self.projectInput->text = canvas->project_name
        ui::ConfirmationDialog::before_render()

      void on_button_selected(string t):
        if t == "OK":
          canvas->save_project()

        self.hide()

  class ImportDialog: public ui::Pager:
    public:
      Canvas *canvas

      ImportDialog(int x, y, w, h, Canvas *c): ui::Pager(x, y, w, h, self):
        self.set_title("Select a png file...")

        self.canvas = c
        self.opt_h = 187
        self.page_size = self.h / self.opt_h - 1

      void populate():
        filenames := util::lsdir(SAVE_DIR, ".png")
        util::sort_by_modified_date(filenames, SAVE_DIR)
        self.options = filenames

      void on_row_selected(string name):
        self.canvas->load_from_png(name)
        self.hide()

      void render_row(ui::HorizontalLayout *row, string option):
        char full_path[PATH_MAX]
        sprintf(full_path, "%s/%s", SAVE_DIR, option.c_str())

        ui::Thumbnail *tn = new ui::Thumbnail(0, 0, 140, self.opt_h, full_path)
        d := new ui::DialogButton(20, 0, self.w-200, self.opt_h, self, option)
        layout->pack_start(row)
        row->pack_start(tn)
        row->pack_start(d)

  class LoadProjectDialog: public ui::Pager:
    public:
      Canvas *canvas
      LoadProjectDialog(int x, y, w, h, Canvas *c): ui::Pager(x, y, w, h, self):
        canvas = c
        self.set_title("Load Project")

      void on_row_selected(string name):
        debug "LOADING PROJECT", name
        canvas->load_project(string(SAVE_DIR) + "/" + name)
        self.hide()

      void populate():
        filenames := util::lsdir(SAVE_DIR, ".hrm")
        util::sort_by_modified_date(filenames, SAVE_DIR)
        self.options = filenames

  class LayerDialog: public ui::Pager:
    public:
    Canvas *canvas
    ExportDialog *sd = NULL
    ImportDialog *id = NULL
    bool on_top = false
    ui::HorizontalLayout *button_bar

    LayerDialog(int x, y, w, h, Canvas* c): ui::Pager(x, y, w, h, self):
      self.set_title("")
      self.canvas = c
      self.opt_h = 55
      self.page_size = (self.h - 100) / self.opt_h

    void on_row_selected(string name):
      canvas->select_layer(name)

    virtual void position_dialog():
      self.restore_coords()
      width, height = self.fb->get_display_size()
      v_layout := ui::VerticalLayout(0, 0, width, height, self.scene)
      if on_top:
        v_layout.pack_start(self, 100)
      else:
        v_layout.pack_center(self)

      h_layout := ui::HorizontalLayout(0, 0, width, height, self.scene)
      h_layout.pack_center(self)

    void populate_and_show():
      // fix the padding sizes for the dialog by making the title smaller
      self.titleWidget = new ui::MultiText(0, 0, self.w, 50, self.title)
      self.contentWidget = new ui::MultiText(20, 0, self.w, self.h - 100, self.content)
      self.populate()
      self.setup_for_render()
      self.show()
      self.setup_buttons()

    ui::DialogButton* make_button(string text, int size=0):
      if size == 0:
        image := stbtext::get_text_size(text, ui::Style::DEFAULT.font_size)
        return new ui::DialogButton(20, 0, image.w + ui::Style::DEFAULT.font_size, 50, self, text)
      return new ui::DialogButton(20, 0, size + ui::Style::DEFAULT.font_size, 50, self, text)

    void add_buttons(ui::HorizontalLayout *bar):
      button_bar = new ui::HorizontalLayout(bar->x, bar->y, bar->w, bar->h, bar->scene)
      setup_buttons()

    void setup_buttons():
      button_bar->start = 0
      button_bar->end = button_bar->w

      button_bar->pack_start(make_button("New Layer"))
      button_bar->pack_start(make_button("Import"))
      button_bar->pack_end(make_button("Delete"), 10)
      button_bar->pack_end(make_button("Export"))

      // add resposition button
      self.add_position_buttons()

    void add_position_buttons():
      flip_button := new ui::Button(self.x + self.w - 51, self.y+1, 50, 50, "")
      if self.on_top:
        flip_button->icon = ICON(assets::icons_fa_chevron_down_solid_png)
      else:
        flip_button->icon = ICON(assets::icons_fa_chevron_up_solid_png)
      flip_button->mouse.click += PLS_LAMBDA(auto &ev):
        self.on_top = !self.on_top
        self.populate_and_show()
      ;
      self.scene->add(flip_button)

    void on_button_selected(string name):
      if name == "New Layer":
        canvas->new_layer()
        self.populate_and_show()
      else if name == "Export":
        filename := canvas->save_layer()
        if self.sd == NULL:
          self.sd = new ExportDialog(0, 0, DIALOG_WIDTH*2, DIALOG_HEIGHT)
          self.sd->on_hide += PLS_LAMBDA(auto ev):
            self.populate_and_show()
          ;
        title := "Saved as " + filename
        self.sd->set_title(title)
        self.sd->show()
        return
      else if name == "Import":
        self.id = new ImportDialog(0, 0, DIALOG_WIDTH, LOAD_DIALOG_HEIGHT, canvas)
        self.id->on_hide += PLS_LAMBDA(auto ev):
          self.populate_and_show()
        ;

        self.id->populate()
        self.id->setup_for_render()
        self.id->show()
        return
      else if name == "Delete":
        layer_id := canvas->cur_layer
        canvas->delete_layer(layer_id)
        canvas->select_layer(0)
        canvas->select_layer(layer_id-1)
      else:
        on_row_selected(name)

      self.populate_and_show()


    void populate():
      self.options.clear()
      for int i = canvas->layers.size()-1; i >= 0; i--:
        options.push_back(canvas->layers[i].name)

    icons::Icon visible_icon(int i):
      if canvas->is_layer_visible(i)
        return ICON(assets::icons_fa_eye_solid_png)
      return ICON(assets::icons_fa_eye_slash_solid_png)

    void render_row(ui::HorizontalLayout *row, string option):
      self.layout->pack_start(row)
      layer_id := canvas->get_layer_idx(option)
      selected_layer := canvas->layers[canvas->cur_layer].name
      bw := 150
      offset := 0
      style := ui::Stylesheet().justify_left().valign_middle()


      // make a button for each of the following: toggle visible,
      // delete, merge down, clear
      visible_button := new ui::Button(0, 0, 50, self.opt_h, "")
      visible_button->icon = ICON(assets::icons_fa_eye_solid_png)
      visible_button->mouse.click += PLS_LAMBDA(auto &ev):
        canvas->toggle_layer(layer_id)
        visible_button->icon = visible_icon(layer_id)
      ;
      offset += 50
      visible_button->set_style(style.justify_center())

      up_button := new ui::Button(0, 0, 50, self.opt_h, "")
      up_button->icon = ICON(assets::icons_fa_chevron_up_solid_png)
      up_button->mouse.click += PLS_LAMBDA(auto &ev):
        canvas->swap_layers(layer_id, layer_id+1)
        canvas->select_layer(selected_layer)
        self.populate_and_show()
      ;
      offset += 50
      up_button->set_style(style.justify_center())

      down_button := new ui::Button(0, 0, 50, self.opt_h, "")
      down_button->icon = ICON(assets::icons_fa_chevron_down_solid_png)
      down_button->mouse.click += PLS_LAMBDA(auto &ev):
        canvas->swap_layers(layer_id, layer_id-1)
        canvas->select_layer(selected_layer)
        self.populate_and_show()
      ;
      offset += 50
      down_button->set_style(style.justify_center())

//      merge_button := new ui::Button(0, 0, 50, self.opt_h, "")
//      merge_button->icon = ICON(assets::icons_fa_object_group_solid_png)
//      merge_button->mouse.click += PLS_LAMBDA(auto &ev):
//        canvas->merge_layers(layer_id, layer_id-1)
//        canvas->select_layer(layer_id-1)
//        self.populate_and_show()
//      ;
//      offset += 50
//      merge_button->set_style(style.justify_center())
//
//      clone_button := new ui::Button(0, 0, 50, self.opt_h, "")
//      clone_button->icon = ICON(assets::icons_fa_clone_solid_png)
//      clone_button->mouse.click += PLS_LAMBDA(auto &ev):
//        canvas->clone_layer(layer_id)
//        canvas->select_layer(layer_id+1)
//        self.populate_and_show()
//      ;
//      offset += 50
//      clone_button->set_style(style.justify_center())

      rename_button := new ui::Button(0, 0, 50, self.opt_h, "")
      rename_button->icon = ICON(assets::icons_fa_file_signature_solid_png)
      rename_button->mouse.click += PLS_LAMBDA(auto &ev):
        keyboard := new ui::Keyboard()
        keyboard->set_text(canvas->layers[layer_id].get_name())
        keyboard->show()

        keyboard->events.done += PLS_LAMBDA(auto &ev):
          canvas->rename_layer(layer_id, ev.text)
          self.populate_and_show()
        ;
      ;
      offset += 100
      rename_button->set_style(style.justify_center())

      // row->pack_end(merge_button)
      // Layer Button
      d := new ui::DialogButton(0, 0, self.w - 60 - offset, self.opt_h, self, option)
      d->x_padding = 10
      d->y_padding = 5
      if option == canvas->layers[canvas->cur_layer].name
        d->set_style(style.border_left())
      else:
        d->set_style(style)

      row->pack_start(visible_button)
      row->pack_start(d)
      row->pack_end(rename_button, 10)
      row->pack_end(down_button, 10)
      row->pack_end(up_button, 10)
//      row->pack_end(merge_button, 10)
//      row->pack_end(clone_button, 10)

