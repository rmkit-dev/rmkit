#include <dirent.h>
#include <libgen.h>

namespace proc:
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
      system(cmd.c_str())
      print base, "IS ALREADY RUNNING, RESUMING"
      return
    print "LAUNCHING PROCESS", name

    proc := name
    if background:
      proc += "&"

    if system(proc.c_str()) != 0:
      pass
