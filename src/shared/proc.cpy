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
#include <thread>
#include <set>
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

  struct MemInfo:
    int total = 0
    int available = 0
    int used = 0
  ;

  std::set<string> known_interpreters {"python", "python3", "bash", "sh"}

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
  bool check_args(string cmdline, vector<string> &args):
    found := false
    cmd_tokens := str_utils::split(cmdline, 0)

    for auto cmd_token : cmd_tokens:
      if cmd_token.size() > 0 && cmd_token[0] == '-':
        continue

      base := cmd_token.c_str()
      full_str := string(base)
      base = basename((char *) base)
      base_str := string(base)

      auto search_interpreter = known_interpreters.find(base_str)
      if search_interpreter != known_interpreters.end():
          continue

      for auto needle : args:
        if base_str == needle || full_str == needle:
          found = true
          break

      break

    return found

  vector<Proc> list_procs(vector<string> &args):
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

  void groupkill(int signal, vector<string> &args):
    procs := list_procs(args)
    unordered_set<string> tokill
    for auto proc : procs:
      tokill.insert(proc.stat[PGROUP])

    for auto p: tokill:
      pid := std::stoi(p)
      ret := kill(-pid, signal)
      debug "SENDING", signal, "TO GROUP", -pid, "RET", ret

  bool is_running(string bin):
    vector<string> bins = { bin }
    procs := list_procs(bins)
    if procs.size() == 0:
      return false

    pid := procs[0].pid
    fname := join_path({"/proc/", to_string(pid), "/wchan"})

    ifstream f(fname)
    string status
    getline(f, status)

    return status != "do_signal_stop"

  map<string, bool> is_running(vector<string> bins, vector<Proc> &procs):
    map<string, bool> ret;
    for auto proc : procs:
      for auto bin : bins:
        args := vector<string> { bin }
        if check_args(proc.cmdline, args):
          ret[bin] = true

    return ret

  map<string, bool> is_running(vector<string> bins):
    procs := list_procs(bins)
    return is_running(bins, procs)

  MemInfo read_mem_total():
    mem_info := MemInfo{}
    fname := "/proc/meminfo"
    string line
    int val = 0
    ifstream f(fname)
    while getline(f, line):
      tokens := str_utils::split(line, ':')
      if tokens.size() > 1:
        try:
          val = stoi(tokens[1])
        catch(...):
          continue

        if tokens[0] == "MemTotal":
          mem_info.total = val

        if tokens[0] == "MemAvailable":
          mem_info.available = val

    mem_info.used = mem_info.total - mem_info.available

    return mem_info

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

  int read_mem_from_smaps(string fname):
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
        if tokens[0].find("Shared") == 0:
          val := stoi(val_tokens[0])
          shared += val
        if tokens[0].find("Private") == 0:
          val := stoi(val_tokens[0])
          priv += val
        if tokens[0] == "Pss":
          val := stoi(val_tokens[0])
          pss += val
        if tokens[0] == "Swap":
          val := stoi(val_tokens[0])
          swap += val
        if tokens[0] == "SwapPss":
          val := stoi(val_tokens[0])
          swap_pss += val


    if pss > 0:
      shared = pss - priv

    return priv

  // collect per process memory usage
  map<int, int> collect_mem(vector<Proc> pids):
    int val
    map<int, int> mem_usage;
    for auto p: pids:
      fname := join_path({"/proc/", to_string(p.pid), "/smaps_rollup"})
      try:
        val = mem_usage[p.pid] = read_mem_from_smaps(fname)
      catch(...):
        pass

      if val == 0:
        fname = join_path({"/proc/", to_string(p.pid), "/smaps"})
        try:
          val = mem_usage[p.pid] = read_mem_from_smaps(fname)
        catch(...):
          pass

      if val == 0:
        mem_usage[p.pid] = read_mem_from_status(p.pid)

    return mem_usage


  void stop_programs(vector<string> programs, string signal=""):
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

  void stop_xochitl():
    #ifdef REMARKABLE
    if system("systemctl stop xochitl 2> /dev/null") == 0:
      debug "STOPPED XOCHITL"
    #endif
    return

  void start_xochitl():
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
    args := vector<string>{name}
    procs := list_procs(args)
    debug "CHECKING PROCESS", name, procs.size()
    return procs.size() > 0

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
      proc = "setsid " + proc

    auto *th = new thread([=]() {
      c_str := proc.c_str()
      _ := system(c_str)

      debug "PROGRAM EXITED"
    })
