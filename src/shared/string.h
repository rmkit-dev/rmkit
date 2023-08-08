#ifndef ____SHARED__STRING_CPY_H
#define ____SHARED__STRING_CPY_H
#include <vector>
using namespace std;
#include <algorithm>
#include <cctype>
#include <locale>
#include <sstream>



namespace str_utils {

static inline void ltrim(std::string &s) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](int ch) {
        return !std::isspace(ch) && std::isprint(ch);
    }));
}


static inline void rtrim(std::string &s) {
    s.erase(std::find_if(s.rbegin(), s.rend(), [](int ch) {
        return !std::isspace(ch) && std::isprint(ch);
    }).base(), s.end());
}


static inline void trim(std::string &s) {
    ltrim(s);
    rtrim(s);
}



static inline std::string ltrim_copy(std::string s) {
    ltrim(s);
    return s;
}


static inline std::string rtrim_copy(std::string s) {
    rtrim(s);
    return s;
}


static inline std::string trim_copy(std::string s) {
    trim(s);
    return s;
}

static inline std::string join(std::vector<std::string> strs, char d=' ') {
  std::string r = "";
  for (auto s : strs) {
    r += s + string(1, d);
  }

  r.resize(r.size()-1);

  return r;
}

std::vector<std::string> split (const std::string &s, char delim) {
  std::vector<std::string> result;
  std::stringstream ss (s);
  std::string item;

  string d(1, delim);
  while (getline (ss, item, delim)) {
    if (item != "" && item != d)
      result.push_back (item);
  }

  return result;
}

bool ends_with (std::string const &fullString, std::string const &ending) {
    if (fullString.length() >= ending.length()) {
        return (0 == fullString.compare (fullString.length() - ending.length(), ending.length(), ending));
    } else {
        return false;
    }
}




};

#endif