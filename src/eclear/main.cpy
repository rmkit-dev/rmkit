#include "../build/rmkit.h"

def main():
  fb := framebuffer::get()

  fb->clear_screen()

  fb->waveform_mode = WAVEFORM_MODE_GC16
  fb->redraw_screen(true)

