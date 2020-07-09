# Perf Profiling

## Using perf

```
sudo perf record ./build/bin/harmony
sudo perf report
```

## Using gprof

* add -pg flag to makefile
* run program and when it finishes, take gmon.out and run `gprof <harmony> gmon.out` to get the call graphs

## Using pidstat

`pidstat -u -C harmony -h 3` : count CPU usage on a 3 second basis for harmony
binary. this is most useful when SSHing into the tablet to analyze the CPU
consumption while activity is being performed

## Valgrind

`sudo valgrind --leak-check=full --track-origins=yes ./build/bin/harmony` to find memory leaks
