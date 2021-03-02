// reading remux.conf file

class RemuxConfig:
  public:
  vector<pair<string, string>> values
  RemuxConfig():
    pass

  vector<string> get_array(string key):
    vector<string> ret
    for auto p : values:
      if p.first == key:
        ret.push_back(p.second)

    return ret

  string get_value(string key, default_value=""):
    val := default_value
    for auto p : values:
      if p.first == key:
        val = p.second

    return val

  bool get_bool(string key, bool default_value=false):
    val := default_value
    for auto p : values:
      if p.first == key:
        if p.second == "yes" or p.second == "true" or p.second == "1":
          val = true
        else if p.second == "no" or p.second == "false" or p.second == "" or p.second == "0":
          val = false
        else:
          debug "* KEY", key, "HAS UNRECOGNIZED BOOLEAN VALUE:", p.second, "MUST BE 'yes' or 'no'"
          debug "  DEFAULTING TO", default_value

    return val

  bool has_key(string key):
    for auto p : values:
      if p.first == key:
        return true

    return false

  void set(string key, value):
    self.values.push_back({key, value})

  int size():
    return self.values.size()


def read_remux_config():
  string line
  #ifndef DEV
  _ := system("mkdir -p /home/root/.config/remux/ 2> /dev/null")
  config_file := "/home/root/.config/remux/remux.conf"
  #else
  config_file := "remux.conf"
  #endif
  debug "READING CONFIG FROM", config_file
  ifstream f(config_file)

  config := RemuxConfig()

  while getline(f, line):
    tokens := str_utils::split(line, '=')
    while tokens.size() > 2:
      tokens[tokens.size()-2] += "=" + tokens[tokens.size()-1]
      tokens.pop_back()

    if tokens.size() == 2:
      config.set(tokens[0], tokens[1])
    else if tokens.size() == 1:
      config.set(tokens[0], "")

  return config
