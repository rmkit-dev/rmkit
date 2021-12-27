// @nosplit
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

namespace util:
  const int VERSION_MAX = 1024
  enum RM_VERSION { UNKNOWN=0, RM1, RM2 }
  static char VERSION_STR[VERSION_MAX]
  static int CUR_VERSION = -1
  static int get_remarkable_version():
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
        while version_str.size() > 0 && std::isspace(version_str.back()):
          version_str.resize(version_str.size()-1)

        if version_str == string("reMarkable 1"):
          CUR_VERSION = RM1
        if version_str == string("reMarkable 1.0"):
          CUR_VERSION = RM1
        if version_str == string("reMarkable Prototype 1"):
          CUR_VERSION = RM1
        if version_str == string("reMarkable 2.0"):
          CUR_VERSION = RM2
      } while (false);

    return CUR_VERSION
