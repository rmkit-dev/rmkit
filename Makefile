FILES=fb_map.cpy fb.cpy mxcfb.h defines.h
HOST?=10.11.99.1
EXE="sketchy"

default: sketchy

sketchy: compile

compile:
	cd okp/ && okp -for -d ../cpp/ -o ../${EXE} ${FILES}

compile_arm:
	export CXX=arm-linux-gnueabihf-g++ 
	cd okp/ && okp -for -d ../cpp/ -o ../${EXE} ${FILES} -- -D"REMARKABLE=1"

test_arm: compile_arm
	scp a.out root@${HOST}:a.out
	ssh root@${HOST} ./a.out
