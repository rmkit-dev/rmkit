# About

This repo contains code for drawing to the remarkable framebuffer.


## Status

Almost nothing is implemented yet. But future plans is to create helper classes for the following:

* Framebuffer abstraction
* Drawing primitives: line, rect, circle, etc
* Widgets and Immediate mode UI: Buttons, Dropdown, Toolbar, etc

## Development

### Install Requirements

* install okp: `sudo pip install okp`
* install arm toolchain
  * on ubuntu: `sudo apt install gcc-arm-linux-gnueabihf`

### Compiling

* compile for linux usage: `make compile`
* compile for remarkable: `make compile_arm`
* test on remarkable: `make test_arm` - assumes that the remarkable is plugged in on USB
