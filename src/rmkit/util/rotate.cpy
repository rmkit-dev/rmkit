// @nosplit
#include <fstream>

namespace util:
  static int rotation = -1
  static int get_rotation():
    if rotation != -1:
      return rotation

    size_f := ifstream("/sys/class/graphics/fb0/rotate")
    string rotate_s
    getline(size_f, rotate_s)

    rotation = stoi(rotate_s)

    return rotation
