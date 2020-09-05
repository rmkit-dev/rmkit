#include <dirent.h>
#include <libgen.h>
#include "string.h"

// {{{ from https://stackoverflow.com/questions/478898/how-do-i-execute-a-command-and-get-the-output-of-the-command-within-c-using-po
```
#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <array>
#include <fstream>

std::string exec(const char* cmd) {
    std::array<char, 128> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}
```
// }}}


namespace proc:
  bool is_running(string bin):
    char command[PATH_MAX]
    sprintf(command, "pidof %s 2> /dev/null", bin.c_str());
    pid := exec(command)
    if pid == "":
      return false

    str_utils::trim(pid)
    fname := "/proc/" + pid + "/wchan"
    ifstream f(fname)
    string status
    getline(f, status)

    return status != "do_signal_stop"

  string get_running_app(vector<string> binaries):
    cmd := "pidof " + str_utils::join(binaries, ' ') + " 2>/dev/null"
    pids := str_utils::split(exec(cmd.c_str()), ' ')

    for auto pid : pids:
      str_utils::trim(pid)
      ifstream f1("/proc/" + pid + "/wchan")
      string status
      getline(f1, status)

      if status != "do_signal_stop":
        ifstream f2("/proc/" + pid + "/cmdline")
        string name
        getline(f2, name)
        str_utils::trim(name)
        return name
    return ""

  def stop_programs(vector<string> programs, string signal=""):
    for auto s : programs:
      #ifdef REMARKABLE
      cmd := "killall" + signal + " " + s + " 2> /dev/null"
      if system(cmd.c_str()) == 0:
        if signal != "":
          print "SENT", signal, "TO", s
        else:
          print "KILLED", s
      #endif
      pass
    return

  def stop_xochitl():
    #ifdef REMARKABLE
    if system("systemctl stop xochitl 2> /dev/null") == 0:
      print "STOPPED XOCHITL"
    #endif
    return

  def start_xochitl():
    #ifdef REMARKABLE
    if system("systemctl restart xochitl 2> /dev/null") == 0:
      print "STARTING XOCHITL"
    #endif
    return

  bool exe_exists(string name):
    char command[PATH_MAX]
    sprintf(command, "test -x %s", name.c_str());
    return 0 == system(command);

  bool check_process(string name):
    print "CHECKING PROCESS", name
    char command[PATH_MAX]
    sprintf(command, "pidof %s 2>&1 > /dev/null", name.c_str());
    return 0 == system(command);

  void launch_process(string name, bool check_running=false, background=false):
    cstr := name.c_str()
    base := basename((char *) cstr)
    if check_running && check_process(base):
      cmd := "killall -SIGCONT " + string(base) + " 2> /dev/null"
      _ := system(cmd.c_str())
      print base, "IS ALREADY RUNNING, RESUMING"
      return

    proc := name
    if background:
      proc = "setsid " + proc + " &"

    if system(proc.c_str()) != 0:
      pass
