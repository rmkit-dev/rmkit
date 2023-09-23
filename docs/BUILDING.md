## Individual Projects

You can compile an individual project by running `make <project>` or `make
<project>_docker` to build the project inside a docker container.

You can change whether you are compiling for the remarkable or a PC by
adjusting the `TARGET` environment variable. See `src/actions.make` for the list
of targets, which include (but is not limited to) `dev`, `kobo` and `rm`

## Compilation

### Cross Compile for Remarkable with Docker

This is the easiest way to compile for the tablet if you have docker installed.

* install docker
* run `make docker` from root of the git repo
* look in artifacts/ for the binaries and release files

### Linux

* install okp: `pip install okp`
* install resim viewer: `pip install rmkit-sim`
* compile with DEV mode: `TARGET=dev make harmony`
* run harmony with `resim ./src/build/harmony`

### Remarkable

* install okp: `sudo pip install okp`
* install arm toolchain
  * on ubuntu: `sudo apt install g++-arm-linux-gnueabihf`
  * on archlinux: install `arm-linux-gnueabihf-gcc` from AUR
* compile harmony for remarkable: `make harmony`
* test on remarkable: `make run_harmony` - assumes that the remarkable is plugged in on USB
* test on remarkable over wifi: `HOST=192.168.1.10 make run_harmony`
