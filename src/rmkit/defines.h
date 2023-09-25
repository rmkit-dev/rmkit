#ifndef DEFINES_H
#define DEFINES_H

#include <vector>
#include <string>
#include <sstream>
#include "ui/icons.h"
#include "color.h"

// #define PERF_BUILD

#define ICON(name) icons::Icon { name, name ## _len, #name}

#if defined(REMARKABLE)
#define SAVE_DIR "/home/root/harmony/saved_images"
#elif defined(KOBO)
#define SAVE_DIR "/opt/data/harmony/"
#else
#define SAVE_DIR "./saved_images"
#endif

#ifdef DEV
// #define DEV_KBD "/dev/input/by-path/pci-0000:24:00.3-usb-0:3.2:1.0-event-kbd"
// #define DEV_KBD "/dev/input/by-path/platform-i8042-serio-0-event-kbd"
#endif

// {{{ CANVAS RELATED DEFINES
#define ERASER_STYLUS -10
#define ERASER_RUBBER -11
#define TRANSPARENT -12
#define MAX_PRESSURE 4096.0

// }}}

// {{{ MXCFB DEFINES
#define WAVEFORM_MODE_INIT	0x0	/* Screen goes to white (clears) */
#define WAVEFORM_MODE_DU	0x1	/* Grey->white/grey->black */
#define WAVEFORM_MODE_GC16	0x2	/* High fidelity (flashing) */
#define WAVEFORM_MODE_GC4	0x3	/* Lower fidelity */
#define WAVEFORM_MODE_A2	0x4	/* Fast black/white animation */
#define WAVEFORM_MODE_DU4 0x7
#define WAVEFORM_MODE_REAGLD 0x9
#define WAVEFORM_MODE_AUTO 257

#define TEMP_USE_REMARKABLE_DRAW 0x0018
#define EPDC_FLAG_EXP1 0x270ce20

#define EPDC_FLAG_USE_DITHERING_ALPHA 0x3ff00000
// }}}

// {{{ VARIABLE SIZE DEFINES
#ifdef REMARKABLE
  #define pointer_size uint32_t
#else
  #define pointer_size uint64_t
#endif
// }}}


// {{{ DISPLAY RELATED DEFINES
#ifdef DEV
// in dev mode, we are assuming we have remarkable settings
#define MTWIDTH 767
#define MTHEIGHT 1023
#define WACOMWIDTH 15725.0
#define WACOMHEIGHT 20967.0
#define DISPLAYWIDTH 1404
#define DISPLAYHEIGHT 1872.0
#define MT_X_SCALAR (float(DISPLAYWIDTH) / float(MTWIDTH))
#define MT_Y_SCALAR (float(DISPLAYHEIGHT) / float(MTHEIGHT))
#define WACOM_X_SCALAR (float(DISPLAYWIDTH) / float(WACOMWIDTH))
#define WACOM_Y_SCALAR (float(DISPLAYHEIGHT) / float(WACOMHEIGHT))
#endif

#define TOOLBAR_HEIGHT 50
#define ICON_WIDTH 70
// }}}

// {{{ HELPER FUNCTIONS

// {{{ FAST RANd

#define FAST_RAND_MAX float(2<<15)
static unsigned int g_seed;

inline void fast_srand(int seed) {
  g_seed = seed;
}

// Compute a pseudorandom integer.
// Output value in range [0, 32767]
inline int fast_rand(void) {
  g_seed = (214013*g_seed+2531011);
  return (g_seed>>16)&0x7FFF;
}
// }}}

static std::vector<std::string> split (const std::string &s, char delim) {
  std::vector<std::string> result;
  std::stringstream ss (s);
  std::string item;

  ss >> std::ws;
  while (getline (ss, item, delim)) {
    result.push_back (item);
    ss >> std::ws;
  }

  return result;
}

static std::vector<std::string> split_lines(const std::string &s) {
  std::vector<std::string> result;
  std::stringstream ss (s);
  std::string item;
  while (getline (ss, item)) {
    result.push_back (item);
  }
  return result;
}

static bool ends_with (std::string const &fullString, std::string const &ending) {
    if (fullString.length() >= ending.length()) {
        return (0 == fullString.compare (fullString.length() - ending.length(), ending.length(), ending));
    } else {
        return false;
    }
}

// }}}

// {{{ IMAGE DATA STRUCT
struct image_data {
  uint32_t* buffer;
  int w;
  int h;
  int channels = 0;
};
// }}}
#endif
