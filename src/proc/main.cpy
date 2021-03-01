#include "../shared/proc.h"

HELP_STRING := "Usage: proc <command> <args>"

int main(int argc, char* argv[]):
  if argc == 1:
    print HELP_STRING
    return 0

  string subcmd(argv[1])
  vector<string> args;
  for int i = 2; i < argc; i++:
    args.push_back(argv[i])

  if subcmd == "ls":
    procs := proc::list_procs(args)
    mem_usage := proc::collect_mem(procs)
    for auto p : procs:
      print p.pid, p.cmdline, mem_usage[p.pid]
  else if subcmd == "is_running":
    ret := proc::is_running(args)
  else if subcmd == "contall":
    proc::groupkill(SIGCONT, args)
  else if subcmd == "stopall":
    proc::groupkill(SIGSTOP, args)
  else:
    debug "UNRECOGNIZED COMMAND: ", subcmd
