// @nosplit
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "kobo_id.h"

namespace util:
  const int VERSION_MAX = 1024
  enum RM_DEVICE_ID_E { UNKNOWN=0, RM1, RM2 }
  static char VERSION_STR[VERSION_MAX]
  static int RM_CUR_VERSION = -1
  static int get_remarkable_version():
    if RM_CUR_VERSION == -1:
      do {
        RM_CUR_VERSION = UNKNOWN
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
          RM_CUR_VERSION = RM1
        if version_str == string("reMarkable 1.0"):
          RM_CUR_VERSION = RM1
        if version_str == string("reMarkable Prototype 1"):
          RM_CUR_VERSION = RM1
        if version_str == string("reMarkable 2.0"):
          RM_CUR_VERSION = RM2
      } while (false);

    return RM_CUR_VERSION

  static int KOBO_CUR_VERSION = -1
  static int get_kobo_version():
    if KOBO_CUR_VERSION == -1:
      do {
        KOBO_CUR_VERSION = UNKNOWN
        fd := open("/mnt/onboard/.kobo/version", O_RDONLY)
        if fd == -1:
          debug "COULDNT OPEN KOBO VERSION FILE", errno
          break

        int bytes = read(fd, VERSION_STR, VERSION_MAX)
        close(fd)
        if bytes <= 0:
          break

        VERSION_STR[bytes] = 0
        version_str := string(VERSION_STR)
        while version_str.size() > 0 && std::isspace(version_str.back()):
          version_str.resize(version_str.size()-1)

        last_three := version_str.substr(version_str.size() - 3)
        KOBO_CUR_VERSION = atoi(last_three.c_str())

        switch KOBO_CUR_VERSION:
          case util::KOBO_DEVICE_ID_E::DEVICE_KOBO_CLARA_HD:
            debug "RUNNING ON CLARA HD"
            break
          case util::KOBO_DEVICE_ID_E::DEVICE_KOBO_LIBRA_H2O:
            debug "RUNNING ON LIBRA H2O"
            break
          case util::KOBO_DEVICE_ID_E::DEVICE_KOBO_ELIPSA_2E:
            debug "RUNNING ON ELIPSA 2E"
            break
          default:
            debug "*** UNRECOGNIZED KOBO DEVICE, TOUCH MAY NOT WORK ***"

            break
      } while (false);

    return KOBO_CUR_VERSION

