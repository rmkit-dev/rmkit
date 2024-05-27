// @nosplit

#include "../build/rmkit.h"

#include <algorithm>
#include <dirent.h>
#include <string>
#include <vector>

const char* IMAGES_DIR = "/opt/etc/dithering_demo"

vector<string> read_directory(const char * dirname):
  DIR *dir
  struct dirent *ent
  vector<string> filenames

  if ((dir = opendir(dirname)) != NULL):
    while ((ent = readdir (dir)) != NULL):
      str_d_name := string(ent->d_name)
      if str_d_name != "." and str_d_name != ".." and ends_with(str_d_name, "png"):
        filenames.push_back(str_d_name)
    closedir(dir)
  else:
    perror("")
  sort(filenames.begin(),filenames.end())
  return filenames

class DitheredBitmap: public ui::Widget:
  public:
  image_data image = { NULL }
  framebuffer::DITHER::MODE dither_mode = framebuffer::DITHER::NONE

  DitheredBitmap(int x, y, w, h): ui::Widget(x, y, w, h):
    pass

  void render():
    old_dither_mode := fb->dither
    fb->dither = self.dither_mode
    fb->draw_rect(x, y, w, h, WHITE)
    if self.image.buffer != NULL
      fb->draw_bitmap(self.image,
                      self.x + (self.w - self.image.w) / 2,
                      self.y + (self.h - self.image.h) / 2,
                      framebuffer::ALPHA_BLEND, false)
    fb->dither = old_dither_mode

class IApp:
  public:
  virtual void on_image_selected(string) = 0;
  virtual void on_waveform_selected(int) = 0;
  virtual void on_dithering_selected(framebuffer::DITHER::MODE) = 0;

class ImageDropdown : public ui::TextDropdown:
  public:
  IApp *app
  vector<string> filenames

  ImageDropdown(int x, y, w, h, IApp *app) \
      : app(app), \
      ui::TextDropdown(x, y, w, h, "Image selection"):
    self.dir = ui::DropdownButton::DIRECTION::DOWN
    self.populate()

  void populate():
    section := add_section("Select an image");
    self.filenames = read_directory(IMAGES_DIR)
    section->add_options(self.filenames)

  void on_select(int idx):
    app->on_image_selected(self.filenames[idx])

#define WAVEFORM_PAIR(X) std::make_pair<>( #X, X )

class WaveformDropdown : public ui::TextDropdown:
  public:
  IApp *app
  vector<pair<string,int>> modes = %{
     WAVEFORM_PAIR(WAVEFORM_MODE_DU),
     WAVEFORM_PAIR(WAVEFORM_MODE_GC16),
     WAVEFORM_PAIR(WAVEFORM_MODE_GC4),
     WAVEFORM_PAIR(WAVEFORM_MODE_A2),
     WAVEFORM_PAIR(WAVEFORM_MODE_DU4),
     WAVEFORM_PAIR(WAVEFORM_MODE_AUTO)
  }

  WaveformDropdown(int x, y, w, h, IApp *app) \
      : app(app), \
      ui::TextDropdown(x, y, w, h, "Waveform selection"):
    self.dir = ui::DropdownButton::DIRECTION::DOWN
    self.populate()

  void populate():
    section := add_section("Waveform mode")
    vector<string> labels
    for (auto mode : self.modes)
      labels.push_back(mode.first)
    section->add_options(labels)

  void on_select(int idx):
    app->on_waveform_selected(modes[idx].second)

#define DITHER_PAIR(X) std::make_pair<>( #X, framebuffer::DITHER::X )

class DitheringDropdown : public ui::TextDropdown:
  public:
  IApp *app
  vector<pair<string,framebuffer::DITHER::MODE>> modes = %{
     DITHER_PAIR(NONE),
     DITHER_PAIR(BAYER_2),
     DITHER_PAIR(BAYER_16),
     DITHER_PAIR(BLUE_NOISE_2),
     DITHER_PAIR(BLUE_NOISE_16),
  }

  DitheringDropdown(int x, y, w, h, IApp *app) \
      : app(app), \
      ui::TextDropdown(x, y, w, h, "Dithering selection"):
    self.dir = ui::DropdownButton::DIRECTION::DOWN
    self.populate()

  void populate():
    section := add_section("Dithering mode")
    vector<string> labels
    for (auto mode : self.modes)
      labels.push_back(mode.first)
    section->add_options(labels)

  void on_select(int idx):
    app->on_dithering_selected(modes[idx].second)

class App : public IApp:
  public:

  ImageDropdown * image_selector;
  WaveformDropdown * waveform_selector;
  DitheringDropdown * dithering_selector;

  ui::Text * undithered_label
  DitheredBitmap *undithered_bmp
  ui::Text * dithered_label
  DitheredBitmap *dithered_bmp

  image_data image = { NULL, 0 }
  int waveform_mode = WAVEFORM_MODE_DU

  App():
    demo_scene := ui::make_scene()
    ui::MainLoop::set_scene(demo_scene)

    ui::Button::DEFAULT_STYLE += ui::Stylesheet().border_all().justify_center().valign_middle()

    fb := framebuffer::get()
    fb->clear_screen()
    fb->redraw_screen()
    w, h = fb->get_display_size()

    // toolbar
    image_selector = new ImageDropdown(0, 0, 300, 100, self)
    demo_scene->add(image_selector)
    waveform_selector = new WaveformDropdown(300, 0, 300, 100, self)
    demo_scene->add(waveform_selector)
    dithering_selector = new DitheringDropdown(600, 0, 300, 100, self)
    demo_scene->add(dithering_selector)
    refresh_btn := new ui::Button(900, 0, 300, 100, "Refresh")
    refresh_btn->mouse.up += PLS_LAMBDA(auto &ev):
      self.update()
    ;
    demo_scene->add(refresh_btn)

    offset_h := 200
    img_h := 700
    text_h := 36

    // undithered
    undithered_label = new ui::Text(0, offset_h, w, text_h, "Original")
    offset_h += text_h
    demo_scene->add(undithered_label)
    undithered_bmp = new DitheredBitmap(0, offset_h, w, img_h)
    offset_h += img_h
    demo_scene->add(undithered_bmp)

    // dithered
    dithered_label = new ui::Text(0, offset_h, w, text_h, "Dithering: NONE")
    demo_scene->add(dithered_label)
    offset_h += text_h
    dithered_bmp = new DitheredBitmap(0, offset_h, w, img_h)
    demo_scene->add(dithered_bmp)

  void update():
    if dithering_selector->selected == 0:
      dithered_label->text = string("Dithering: NONE")
    else:
      dithered_label->text = string("Dithering: ") + dithering_selector->text
    // Clear the screen
    fb := framebuffer::get()
    fb->waveform_mode = WAVEFORM_MODE_DU
    fb->clear_screen()
    fb->redraw_screen()
    // Refresh widgets
    fb->waveform_mode = self.waveform_mode
    ui::MainLoop::full_refresh()
    // fb->waveform_mode = self.waveform_mode

  void on_image_selected(string filename):
    if self.image.buffer != NULL:
      free(self.image.buffer)
    filename = string(IMAGES_DIR) + "/" + filename
    int channels
    self.image.buffer = (uint32_t*)stbi_load(filename.c_str(), &self.image.w, &self.image.h, &channels, 4);
    self.image.channels = 4
    fb := framebuffer::get()
    w, h = fb->get_display_size()

    if w - 100 < self.image.w:
      float resize_ratio = (self.image.w / ((float) w - 100))
      rw := self.image.w / resize_ratio
      rh := self.image.h / resize_ratio
      util::resize_image(image, rw, rh, 0)
    else:
      util::resize_image(image, self.image.w, self.image.h, 0)

    undithered_bmp->image = self.image
    dithered_bmp->image = self.image
    update()

  void on_waveform_selected(int mode):
    self.waveform_mode = mode
    update()

  void on_dithering_selected(framebuffer::DITHER::MODE mode):
    dithered_bmp->dither_mode = mode
    update()

  def run():
    if !image_selector->filenames.empty():
      self.on_image_selected(image_selector->filenames[0])
    while true:
      ui::MainLoop::main()
      framebuffer::get()->waveform_mode = self.waveform_mode
      ui::MainLoop::redraw()
      ui::MainLoop::read_input()

int main():
  app := App()
  app.run()
