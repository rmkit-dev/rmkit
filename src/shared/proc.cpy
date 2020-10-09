#include <dirent.h>
#include <libgen.h>
#include "string.h"
#include <ctype.h>
#include <iostream>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <unordered_set>
#define PID 1
#define PGROUP 4

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
  struct Proc:
    int pid
    string cmdline
    vector<string> stat
  ;

  string join_path(vector<string> v):
    ostringstream s;
    for const auto& i : v:
      if &i != &v[0]:
        s << "/"
      s << i
    return s.str();

  vector<string> read_dir(string bin_dir, bool set_path=false):
    DIR *dir
    struct dirent *ent

    vector<string> filenames
    if ((dir = opendir (bin_dir.c_str())) != NULL):
      while ((ent = readdir (dir)) != NULL):
        str_d_name := string(ent->d_name)
        if str_d_name != "." and str_d_name != "..":
          if set_path:
            str_d_name = join_path({bin_dir, ent->d_name})
          filenames.push_back(str_d_name)
      closedir (dir)
    else:
      perror ("")

    return filenames

  vector<string> read_pids():
    ret := vector<string>()
    files := read_dir("/proc")
    for auto file : files:
      allnumbers := true
      for auto c : file:
        if not std::isdigit(c):
          allnumbers = false
          break

      if allnumbers:
        ret.push_back(file)

    return ret

  // checks that cmdline contains a value in args
  // BUT it skips any tokens in cmdline that start with '-'
  def check_args(string cmdline, vector<string> &args):
    found := false
    for auto needle : args:
      if cmdline.find(needle) != -1:
        found = true
        break

    if not found:
      return false

    found = false
    cmd_tokens := str_utils::split(cmdline, 0)

    for auto t : cmd_tokens:
      if t[0] == '-':
        continue

      for auto needle : args:
        if t.find(needle) != -1:
          found = true
          break

      if found:
        break

    return found

  def ls(vector<string> &args):
    vector<Proc> ret;

    needle := string("")
    if len(args) > 1:
      needle = args[1]

    string cmdline
    string stat
    pids := read_pids()
    mypid := to_string(getpid())

    for auto p : pids:
      if p == mypid:
        continue

      ifstream f(join_path({"/proc", p, "cmdline"}))
      getline(f, cmdline)
      if cmdline == "":
        continue

      if not check_args(cmdline, args):
        continue

      f = ifstream(join_path({"/proc", p, "stat"}))
      getline(f, stat)
      fields := str_utils::split(stat, ' ')

      ret.push_back(Proc{std::stoi(p), cmdline, fields})

    return ret

  def groupkill(int signal, vector<string> &args):
    procs := ls(args)
    unordered_set<string> tokill
    for auto proc : procs:
      tokill.insert(proc.stat[PGROUP])

    for auto p: tokill:
      pid := std::stoi(p)
      ret := kill(-pid, signal)
      debug "SENDING", signal, "TO GROUP", -pid, "RET", ret

  bool is_running(string bin):
    vector<string> bins = { bin }
    procs := ls(bins)
    if procs.size() == 0:
      return false

    pid := procs[0].pid
    fname := join_path({"/proc/", to_string(pid), "/wchan"})

    ifstream f(fname)
    string status
    getline(f, status)

    return status != "do_signal_stop"

  map<string, bool> is_running(vector<string> bins):
    map<string, bool> ret;
    procs := ls(bins)
    for auto proc : procs:
      for auto bin : bins:
        args := vector<string> { bin }
        if check_args(proc.cmdline, args):
          ret[bin] = true

    return ret

  int read_mem_from_status(int pid):
    val := -1
    fname := join_path({"/proc/", to_string(pid), "/status"})
    ifstream f(fname)
    string line
    while getline(f, line):
      tokens := str_utils::split(line, ':')
      if tokens.size() > 1 and tokens[0] == "VmSize":
        val = stoi(tokens[1])

    return val

  int read_mem_from_smaps_rollup(int pid):
    fname := join_path({"/proc/", to_string(pid), "/smaps_rollup"})
    shared := 0
    priv := 0
    pss := 0
    swap := 0
    swap_pss := 0
    ifstream f(fname)
    string line
    while getline(f, line):
      tokens := str_utils::split(line, ':')
      if tokens.size() > 1:
        val_tokens := str_utils::split(tokens[1], ' ')
        val := stoi(val_tokens[0])
        if tokens[0].find("Shared") == 0:
          shared += val
        if tokens[0].find("Private") == 0:
          priv += val
        if tokens[0] == "Pss":
          pss += val
        if tokens[0] == "Swap":
          swap += val
        if tokens[0] == "SwapPss":
          swap_pss += val


    if pss > 0:
      shared = pss - priv


    return priv

  // collect per process memory usage
  map<int, int> collect_mem(vector<Proc> pids):
    int val
    map<int, int> mem_usage;
    for auto p: pids:
      val = mem_usage[p.pid] = read_mem_from_smaps_rollup(p.pid)
      if val == 0:
        mem_usage[p.pid] = read_mem_from_status(p.pid)

    return mem_usage


  def stop_programs(vector<string> programs, string signal=""):
    for auto s : programs:
      #ifdef REMARKABLE
      cmd := "killall" + signal + " " + s + " 2> /dev/null"
      if system(cmd.c_str()) == 0:
        if signal != "":
          debug "SENT", signal, "TO", s
        else:
          debug "KILLED", s
      #endif
      pass
    return

  def stop_xochitl():
    #ifdef REMARKABLE
    if system("systemctl stop xochitl 2> /dev/null") == 0:
      debug "STOPPED XOCHITL"
    #endif
    return

  def start_xochitl():
    #ifdef REMARKABLE
    if system("systemctl restart xochitl 2> /dev/null") == 0:
      debug "STARTING XOCHITL"
    #endif
    return

  bool exe_exists(string name):
    char command[PATH_MAX]
    sprintf(command, "test -x %s", name.c_str());
    return 0 == system(command);

  bool check_process(string name):
    debug "CHECKING PROCESS", name
    char command[PATH_MAX]
    sprintf(command, "pidof %s 2>&1 > /dev/null", name.c_str());
    return 0 == system(command);

  void launch_process(string name, bool check_running=false, background=false):
    tokens := str_utils::split(name, ' ')
    cstr := tokens[0].c_str()
    base := string(basename((char *) cstr))
    if check_running && check_process(base):
      debug base, "IS ALREADY RUNNING, RESUMING"
      term := vector<string> { base }
      groupkill(SIGCONT, term)
      return

    proc := name
    if background:
      proc = "setsid " + proc + " &"

    if system(proc.c_str()) != 0:
      pass

