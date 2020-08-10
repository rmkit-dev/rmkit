## Individual Projects

You can compile an individual project by going to its directory and
running `make` or `make run`. If it depends on rmkit.h, you should
run `make rmkit.h` in the top level dir.

You can change whether you are compiling for the remarkable or a PC by
adjusting the `ARCH` environment variable. See `src/actions.make` for the list
of architectures, which include (but is not limited to) `dev` and `arm`

## Compilation

### Cross Compile for Remarkable with Docker

This is the easiest way to compile for the tablet if you have docker installed.

* install docker
* run `make docker` from root of the git repo
* look in artifacts/ for the binaries and release files

### Linux

* install okp: `sudo pip install okp`

with framebuffer:

* compile with real framebuffer: `ARCH=x86 make harmony`
* switch to virtual terminal and run `./build/bin/harmony`

with image framebuffer:

* compile with fake framebuffer: `ARCH=dev make harmony`
* run harmony
* run local viewer: `make view`

### Remarkable

* install okp: `sudo pip install okp`
* install arm toolchain
  * on ubuntu: `sudo apt install g++-arm-linux-gnueabihf`
* compile harmony for remarkable: `make harmony_arm`
* test on remarkable: `make test_arm` - assumes that the remarkable is plugged in on USB
* test on remarkable over wifi: `HOST=192.168.1.10 make test_arm`
