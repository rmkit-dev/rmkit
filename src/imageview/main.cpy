#include "../build/rmkit.h"

class App:
  public:

  def open_image(string full_path):
    fb := framebuffer::get()
    fb->clear_screen()
    int iw, ih
    int channels // an output parameter
    decoded := (uint8_t*) stbi_load(full_path.c_str(), &iw, &ih, &channels, 4)

    nw, nh := fb->get_display_size()
    debug "RESIZING TO", nw, nh, channels
    dst := (uint8_t*) malloc(nw * nh * 4)

    aspect_ratio := std::min(nw / (float) iw, nh / (float) ih)

    fw := aspect_ratio * iw
    fh := aspect_ratio * ih

    image := image_data{(uint32_t*) decoded, (int) iw, (int) ih, 4}
    util::resize_image(image, fw, fh, 999)
    fb->draw_bitmap(image,0,0)


  def run():
    ui::MainLoop::refresh()
    ui::MainLoop::redraw()


def main(int argc, char *argv[]):
  App app
  string img = "src/dithering_demo/colorspace.png"
  fb := framebuffer::get()
  fb->dither = framebuffer::DITHER::BAYER_2
  if argc > 1:
    img = argv[1]
  else:
    print "Usage:", argv[0], "<image file>"

  app.open_image(img)
  app.run()
