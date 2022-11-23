#include "../build/rmkit.h"

def main():
  fb := framebuffer::get()

  fb->clear_screen()

  fb->waveform_mode = WAVEFORM_MODE_INIT
  fb->redraw_screen(true)

