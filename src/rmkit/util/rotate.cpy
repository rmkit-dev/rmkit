// @nosplit
#include "machine_id.h"
#include <fstream>

namespace util:
  namespace rotation:
    static int rotation = -1
    enum ROTATION { ROT0 = 0, ROT90 = 1, ROT180 = 2, ROT270 = 3, ROT_UNKNOWN = 4 }

    static void reset():
      rotation = -1

    static int get():
      if rotation != -1:
        return rotation

      #ifdef REMARKABLE
      if CUR_VERSION == RM1:
        return ROT180
      else if CUR_VERSION == RM2:
        return ROT270
      #endif

      size_f := ifstream("/sys/class/graphics/fb0/rotate")
      string rotate_s
      getline(size_f, rotate_s)

      rotation = stoi(rotate_s)

      return rotation
