## Compilation

### Cross Compile for Remarkable with Docker

This is the easiest way to compile for the tablet if you have docker installed.

* install docker
* run `make docker` from root of the git repo
* look in artifacts/ for the binaries and release files

### Linux

* install okp: `sudo pip install okp`

with framebuffer:

* compile with real framebuffer: `make harmony_x86`
* switch to virtual terminal and run `./build/bin/harmony`

with image framebuffer:

* compile with fake framebuffer: `make harmony_dev`
* run harmony
* run local viewer: `make view`

### Remarkable

* install okp: `sudo pip install okp`
* install arm toolchain
  * on ubuntu: `sudo apt install g++-arm-linux-gnueabihf`
* compile harmony for remarkable: `make harmony_arm`
* test on remarkable: `make test_arm` - assumes that the remarkable is plugged in on USB
* test on remarkable over wifi: `HOST=192.168.1.10 make test_arm`
