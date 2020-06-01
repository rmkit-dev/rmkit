FILES=main.cpy fb.cpy mxcfb.h defines.h
HOST?=10.11.99.1
EXE="sketchy"
CPP_FLAGS=-O3 -g
OKP_FLAGS=-for -d ../cpp/ -o ../${EXE} -nr ${FILES}

default: sketchy_dev

sketchy_fb: compile_x86 format

sketchy_dev: compile_dev format

sketchy_arm: compile_arm format

compile_x86:
	cd okp/ && okp ${OKP_FLAGS} -- ${CPP_FLAGS}

compile_arm:
	cd okp/ && CXX=arm-linux-gnueabihf-g++ okp ${OKP_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}

compile_dev:
	cd okp/ && okp ${OKP_FLAGS} -- -D"DEV=1" ${CPP_FLAGS}

test_arm: compile_arm format
	scp sketchy root@${HOST}:sketchy
	ssh root@${HOST} ./sketchy

format:
	clang-format -i cpp/*.h cpp/*.cpp

view:
	python scripts/viewer.py
