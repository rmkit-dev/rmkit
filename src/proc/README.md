# proc

this is a command line tool that is meant to help manage processes better than
the built in busybox tools.

in specific, `proc` is meant to interact with process groups

## commands

```
proc ls
proc killall -SIGSTOP foo
proc kill -SIGSTOP <pid>

# kill process group
proc killall -SIGSTOP -g foo

```
