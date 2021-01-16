# rmkit

[![rm1](https://img.shields.io/badge/rM1-supported-green)](https://remarkable.com/store/remarkable)
[![rm2](https://img.shields.io/badge/rM2-supported-green)](https://remarkable.com/store/remarkable-2)



[![opkg](https://img.shields.io/badge/OPKG-harmony-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-mines-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-nao-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-remux-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-simple-blue)](https://github.com/toltec-dev/toltec)

This repo contains applications for the remarkable tablet. See the README in
each application's directory to learn more about it. The general purpose of
rmkit is to make it easy to write and deploy new apps to the remarkable tablet.

NOTE: for remarkable2 support, [rm2fb](https://github.com/ddvk/remarkable2-framebuffer) is required

## Apps & Libaries

### [harmony](src/harmony)

A [low latency drawing app](https://rmkit.dev/apps/harmony) with procedural brushes

### [mines](src/minesweeper)

A [minesweeper game](https://rmkit.dev/apps/minesweeper) for spending time between meetings and classes

### [nao](src/nao)

A [package manager](https://rmkit.dev/apps/nao) for opkg built in bash + simple app script.

### [remux](src/remux)

An [app switcher](https://rmkit.dev/apps/remux) for switching between apps on the remarkable that is compatible
with [draft-remarkable](https://github.com/dixonary/draft-reMarkable/)
configuration files. Hold the middle button or swipe up the side of the display to bring it up.

### [rmkit](src/rmkit)

A batteries included library for building remarkable apps. [Read the documentation](https://docs.rmkit.dev)

### [simple app script](src/simple)

A [simple markup language](https://rmkit.dev/apps/sas) for building apps that
follow the philosophy of unix pipes.

### [genie](src/genie)

[genie](https://rmkit.dev/apps/genie) is a config based gesture launcher.
specify gestures and actions and get gesturing!

### [lamp](src/lamp)

[lamp](https://rmkit.dev/apps/lamp) is a config based stroke injector, useful
for injecting finger or stylus events.

### [bufshot](src/bufshot)

bufshot saves the framebuffer into a png file, works for rm1 or rm2 (using
rm2fb)

## Demos

### [animation](src/animation_demo)

An example of generating multiple animations using idle timers

### [drawing](src/drawing_demo)

A simple black/white drawing demo

### [input demo](src/input_demo)

An app with a keyboard input and range slider

## Installation

#### Via Toltec

The recommended way of installing the software in this repository is to use
[toltec](https://github.com/toltec-dev/toltec) - a free software repository for
remarkable. Once opkg and the toltec repository are setup, use `opkg install
remux` to get remux, for example.

If you are feeling adventurous, you can try out the bootstrap script from
linusCDE that installs opkg, toltec and the rmkit packages in one line: `wget -qO-
https://rmkit.dev/bs | sh -C harmony minesweeper remux nao`

#### Build Server

Binaries are generated on every push to this git repository and are hosted at
https://build.rmkit.dev

## Building from source

see [BUILDING.md](docs/BUILDING.md)

## Have ideas or want to code your own apps?

[There's a list of app ideas just waiting to be built!](docs/APP_IDEAS.md). If
you have ideas for new apps or features, please open an issue or get in touch
:-D
