# rmkit

[![rm1](https://img.shields.io/badge/rM1-supported-green)](https://remarkable.com/store/remarkable)
[![rm2](https://img.shields.io/badge/rM2-supported-green)](https://remarkable.com/store/remarkable-2)
[![Kobo Aura One](https://img.shields.io/badge/Kobo_Aura_One-supported-green)](https://us.kobobooks.com/products/kobo-aura-one/)
[![Kobo Clara HD](https://img.shields.io/badge/Kobo_Clara_HD-supported-green)](https://us.kobobooks.com/products/kobo-clara-hd)
[![Kobo Libra H20](https://img.shields.io/badge/Kobo_Libra_H2O-supported-green)](https://us.kobobooks.com/products/kobo-libra-h2o)
[![Kobo Elipsa 2E](https://img.shields.io/badge/Kobo_Elipsa_2E-supported-green)](https://us.kobobooks.com/products/kobo-elipsa-2e)
[![Kobo Libra Colour](https://img.shields.io/badge/Kobo_Libra_Colour-supported-green)](https://us.kobobooks.com/products/kobo-libra-colour)
[![Kobo Clara Colour](https://img.shields.io/badge/Kobo_Clara_Colour-supported-green)](https://us.kobobooks.com/products/kobo-clara-colour)


[![opkg](https://img.shields.io/badge/OPKG-harmony-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-mines-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-nao-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-remux-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-simple-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-bufshot-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-iago-blue)](https://github.com/toltec-dev/toltec)
[![opkg](https://img.shields.io/badge/OPKG-genie-blue)](https://github.com/toltec-dev/toltec)

This repo contains applications for the remarkable tablet and kobo ereaders.
See the README in each application's directory to learn more about it. The
general purpose of rmkit is to make it easy to write and deploy new apps to eink devices.

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
configuration files. Hold the middle button or [swipe up the side of the display](https://imgur.com/a/rT94L8W) to bring it up.

NOTE: if you have trouble with swiping, tap the screen with your finger once
and then swipe, this should help a bit.

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

### [iago](src/iago)

[iago](https://rmkit.dev/apps/iago) is an overlay for drawing shapes like
lines, squares and circles.

### [rpncalc](src/rpncalc)

rpncalc is calculator app that uses reverse polish notation and a stack for
evaluation.

### [wordlet](src/wordlet)

Wordlet is a clone of the popular [wordle](https://www.powerlanguage.co.uk/wordle/) game

### [dumbskull](src/dumbskull)

Dumbskull is a port of the games [donsol](https://100r.co/site/donsol.html) and
[scoundrel](https://stfj.net/index2.php?project=art/2011/Scoundrel.pdf). It's a dungeon
crawl themed solitaire that uses a standard playing card deck.

## Demos

### [animation](src/animation_demo)

An example of generating multiple animations using idle timers

### [drawing](src/drawing_demo)

A simple black/white drawing demo

### [input demo](src/input_demo)

An app with a keyboard input and range slider

## Installation

#### rM via Toltec

The recommended way of installing the software in this repository is to use
[toltec](https://github.com/toltec-dev/toltec) - a free software repository for
remarkable. Once opkg and the toltec repository are setup, use `opkg install
remux` to get remux, for example.

#### Kobo

**NOTE: Only Kobo Clara HD, Libra H2O and Kobo Elipsa 2E are supported**

To install on Kobo devices, download [KoboRoot.tgz](https://build.rmkit.dev/master/latest/kobo/KoboRoot.tgz) and place it in `KOBOReader/.kobo/` after mounting your Kobo reader. This will install remux and a few demo applications. To disable remux, remove `KOBOReader/.adds/rmkit/enable_remux`

#### Build Server

Binaries are generated on every push to this git repository and are hosted at
https://build.rmkit.dev

## Building from source

see [BUILDING.md](docs/BUILDING.md)

## Have ideas or want to code your own apps?

[There's a list of app ideas just waiting to be built!](docs/APP_IDEAS.md). If
you have ideas for new apps or features, please open an issue or get in touch
:-D

## Acknowledgements

* [libremarkable](https://github.com/canselcik/libremarkable) for reverse engineering remarkable IO
* [stb](https://github.com/nothings/stb) for image resizing and font rendering libraries
