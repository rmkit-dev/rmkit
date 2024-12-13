#include <algorithm>
#include <dirent.h>
#include <sys/stat.h>
#include "../shared/string.h"

namespace util:

  static void sort_by_modified_date(vector<string> &filenames, string dirname):
    struct stat buf
    vector<tuple<int, string>> entries
    for (auto filename : filenames)
      string full_path = ""
      full_path.append(dirname).append("/").append(filename)
      if(stat(full_path.c_str(), &buf))
        debug "Failed stat() on ", full_path
        continue
      entries.push_back({buf.st_mtime, filename})

    sort(entries.begin(), entries.end())
    filenames.clear()
    for (auto e : entries)
      filenames.push_back(std::get<1>(e))

    reverse(filenames.begin(), filenames.end())

  static vector<string> lsdir(string dirname, string ext=""):
    DIR *dir
    struct dirent *ent

    vector<string> filenames
    if ((dir = opendir(dirname.c_str())) != NULL):
      while ((ent = readdir (dir)) != NULL):
        str_d_name := string(ent->d_name)
        if str_d_name != "." and str_d_name != ".." and ends_with(str_d_name, ext):
          filenames.push_back(str_d_name)
      closedir (dir)
    else:
      perror ("")

    return filenames
