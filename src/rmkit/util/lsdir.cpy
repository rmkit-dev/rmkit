#include <dirent.h>
#include "../shared/string.h"

namespace util:
  vector<string> lsdir(string dirname, string ext=""):
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
