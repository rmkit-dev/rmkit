FILES=main.cpy fb.cpy mxcfb.h defines.h
HOST?=10.11.99.1
EXE="sketchy"

default: sketchy

sketchy: compile_x86 format

sketchy_arm: compile_arm format

compile_x86:
	cd okp/ && okp -for -d ../cpp/ -o ../${EXE} ${FILES}

compile_arm:
	cd okp/ && CXX=arm-linux-gnueabihf-g++ okp -for -d ../cpp/ -o ../${EXE} ${FILES} -- -D"REMARKABLE=1"

test_arm: compile_arm format
	scp sketchy root@${HOST}:sketchy
	ssh root@${HOST} ./sketchy

format:
	clang-format -i cpp/*.h cpp/*.cpp
