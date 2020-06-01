FILES=main.cpy fb.cpy mxcfb.h defines.h
HOST?=10.11.99.1
EXE="sketchy"
FLAGS=-O3 -g

default: sketchy_dev

sketchy_fb: compile_x86 format

sketchy_dev: compile_dev format

sketchy_arm: compile_arm format

compile_x86:
	cd okp/ && okp -for -d ../cpp/ -o ../${EXE} ${FILES} -- ${FLAGS}

compile_arm:
	cd okp/ && CXX=arm-linux-gnueabihf-g++ okp -for -d ../cpp/ -o ../${EXE} ${FILES} -- -D"REMARKABLE=1" -- ${FLAGS}

compile_dev:
	cd okp/ && okp -for -d ../cpp/ -o ../${EXE} ${FILES} -- -D"DEV=1" ${FLAGS}

test_arm: compile_arm format
	scp sketchy root@${HOST}:sketchy
	ssh root@${HOST} ./sketchy

format:
	clang-format -i cpp/*.h cpp/*.cpp
