#include "config.launcher.h"

#ifndef DEV
#define BIN_DIR  "/home/root/apps/"
#define DOT_BIN_DIR  "/opt/bin/apps/"
#define DRAFT_DIR "/etc/draft/"
#define OPT_DRAFT_DIR "/opt/etc/draft/"
#define CACHE_DIR "/home/root/.cache/remux"
#else
#define CACHE_DIR "./src/tmp"
#define BIN_DIR  "./src/build/"
#define DOT_BIN_DIR  "./src/build/.build"
#define DRAFT_DIR "./src/remux/draft"
#define OPT_DRAFT_DIR "/nowhere/nothing"
#endif

EXE_EXT := ".exe"

```
#include <sys/stat.h>

bool can_exec(const char *file)
{
    struct stat  st;

    if (stat(file, &st) < 0)
        return false;
    if ((st.st_mode & S_IEXEC) != 0)
        return true;
    return false;
}
```

bool string_to_bool(string key, string s, bool default_value=false):
  bool val = default_value
  if s == "yes" or s == "true" or s == "1":
    val = true
  else if s == "no" or s == "false" or s == "" or s == "0":
    val = false
  else:
    debug "* KEY", key, "HAS UNRECOGNIZED BOOLEAN VALUE:", s, "MUST BE 'yes' or 'no'"
    debug "  DEFAULTING TO", default_value

  return val

class AppReader:
  public:
  vector<RMApp> apps
  vector<RMApp> read_draft_from_dir(string bin_dir):
    DIR *dir
    struct dirent *ent

    vector<RMApp> apps
    char resolved_path[PATH_MAX];
    if ((dir = opendir (bin_dir.c_str())) != NULL):
      while ((ent = readdir (dir)) != NULL):
        str_d_name := string(ent->d_name)
        if str_d_name == "." or str_d_name == "..":
          continue

        path := string(bin_dir) + "/" + string(ent->d_name)
        ifstream filein(path)
        string line

        RMApp rmapp
        rmapp.bin = "";
        while filein.good():
          getline(filein, line)
          tokens := split(line, '=')
          if tokens.size() == 2:
            arg := tokens[0]
            val := tokens[1]
            if arg == "call":
              rmapp.bin = val
            else if arg == "desc":
              rmapp.desc = val
            else if arg == "name":
              rmapp.name = val
            else if arg == "term":
              rmapp.term = val
            else if arg == "manage_power":
              rmapp.manage_power = string_to_bool(arg, val, true)

        if rmapp.bin != "":
          apps.push_back(rmapp)

      closedir (dir)
    else:
      perror ("")

    vector<string> skip_list = { "remux", "remux.exe", "xochitl", "/usr/bin/xochitl", "/opt/bin/xochitl" }
    for auto a : apps:
      dont_add := false
      for auto s : skip_list:
        if s == a.bin:
          dont_add = true
      if dont_add:
        continue

      self.apps.push_back(a)
    return apps

  def read_apps_from_dir(string bin_dir):
    DIR *dir
    struct dirent *ent

    vector<string> filenames
    char resolved_path[PATH_MAX];
    if ((dir = opendir (bin_dir.c_str())) != NULL):
      while ((ent = readdir (dir)) != NULL):
        str_d_name := string(ent->d_name)
        path := string(bin_dir) + string(ent->d_name)
        if str_d_name != "." and str_d_name != ".." and can_exec(path.c_str()):
          _ := realpath(path.c_str(), resolved_path);
          str_d_name = string(resolved_path)
          filenames.push_back(str_d_name)
      closedir (dir)
    else:
      perror ("")
    sort(filenames.begin(),filenames.end())
    return filenames

  def read_binaries_from_dir(string dir):
    vector<string> skip_list = { "remux", "remux.exe" }
    bin_binaries := read_apps_from_dir(dir)
    for auto a : bin_binaries:
      bin_str := string(a)
      app_s := a.c_str()
      base_s := basename((char *) app_s)

      dont_add := false
      for auto s : skip_list:
        if s == base_s:
          dont_add = true
      if dont_add:
        continue


      base_str := string(base_s)
      name_str := base_str
      if ends_with(base_str, EXE_EXT):
        name_str = base_str.substr(0, base_str.length() - sizeof(EXE_EXT))

      app := (RMApp) { .bin=bin_str, .which=base_str, .name=name_str }
      self.apps.push_back(app)

  void populate():
    vector<string> skip_list = { "remux", "remux.exe" }
    self.apps = {}

    for auto a : APPS:
      if a.always_show || proc::exe_exists(a.bin):
        self.apps.push_back(a)

    read_draft_from_dir(DRAFT_DIR)
    read_draft_from_dir(OPT_DRAFT_DIR)

    read_binaries_from_dir(BIN_DIR)
    read_binaries_from_dir(DOT_BIN_DIR)

    vector<string> bins
    for auto &app : self.apps:
      app.is_running = false
      bins.push_back(app.bin)

    procs := proc::list_procs(bins)
    is_running := proc::is_running(bins, procs)

    for auto &app : self.apps:
      if is_running.find(app.bin) != is_running.end():
        app.is_running = true

    ClockWatch cm
    mem_usage := proc::collect_group_mem(procs)
    for auto &app : self.apps:
      app.mem_usage = 0
      for auto proc : procs:
        bs := vector<string> { app.bin }
        if proc::check_args(proc.cmdline, bs)
          app.mem_usage += mem_usage[proc.pgrp]
    debug "memory stats took", cm.elapsed()

  def get_binaries():
    vector<string> binaries
    unordered_set<string> seen
    for auto a : self.apps:
      auto name = a.name
      if seen.find(a.bin) != seen.end():
        continue

      seen.insert(a.bin)
      if name == "":
        name = a.bin
      binaries.push_back(name)
    return binaries

  def get_apps():
    return self.apps
