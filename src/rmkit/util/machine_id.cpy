#include "../../shared/string.h"

#define VERSION_MAX 1024
namespace util:
  enum RM_VERSION { UNKNOWN=0, RM1, RM2 }
  char VERSION_STR[VERSION_MAX]
  int get_remarkable_version():
    static int CUR_VERSION = -1
    if CUR_VERSION == -1:
      do {
        CUR_VERSION = UNKNOWN
        fd := open("/sys/devices/soc0/machine", O_RDONLY)
        if fd == -1:
          debug "COULDNT OPEN machine id FILE", errno
          break

        int bytes = read(fd, VERSION_STR, VERSION_MAX)
        close(fd)
        if bytes <= 0:
          break

        VERSION_STR[bytes] = 0
        version_str := string(VERSION_STR)
        str_utils::trim(version_str)

        if version_str == string("reMarkable 1"):
          CUR_VERSION = RM1
        if version_str == string("reMarkable Prototype 1"):
          CUR_VERSION = RM1
        if version_str == string("reMarkable 2.0"):
          CUR_VERSION = RM2
      } while (false);

    return CUR_VERSION
#undef VERSION_MAX
