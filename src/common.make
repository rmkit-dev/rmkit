HOST?=10.11.99.1
TARGET?=rm
CXX_BIN?=arm-linux-gnueabihf-g++
CC_BIN?=arm-linux-gnueabihf-gcc
STRIP_BIN?=arm-linux-gnueabihf-strip
CPP_FLAGS=-pthread -lpthread -fdata-sections -ffunction-sections -Wl,--gc-sections

# BUILD STUFF
ROOT=${PWD}
BUILD_DIR=src/build


VERSION=$(shell cat src/rmkit/version.cpy | sed 's/__version__=//;s/"//g')
KBD=`ls /dev/input/by-path/*kbd | head -n1`
# NOTE: $FILES and $EXE NEED TO BE DEFINED
RMKIT_IMPL="RMKIT_IMPLEMENTATION"
OKP_FLAGS=-ig ${RMKIT_IMPL} -ns -ni -for -d ../.${APP}_cpp/ -o ../build/${EXE} ${FILES}

# installation directory on remarkable
DEST?=/opt/bin/

# vim: syntax=make
