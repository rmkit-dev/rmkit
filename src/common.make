HOST?=10.11.99.1
ARCH?=arm
CXX=arm-linux-gnueabihf-g++
CC = arm-linux-gnueabihf-gcc
CPP_FLAGS=-pthread -lpthread

# BUILD STUFF
ROOT=${PWD}
BUILD_DIR=src/build


VERSION=$(shell cat src/rmkit/version.cpy | sed 's/__version__=//;s/"//g')
KBD=`ls /dev/input/by-path/*kbd | head -n1`
# NOTE: $FILES and $EXE NEED TO BE DEFINED
OKP_FLAGS=-ni -for -d ../cpp/ -o ../build/${EXE} ${FILES}

# vim: syntax=make
