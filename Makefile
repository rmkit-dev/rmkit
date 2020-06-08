FILES=main.cpy
HOST?=10.11.99.1
EXE="sketchy"
CPP_FLAGS=-O3 -g
OKP_FLAGS=-for -d ../cpp/ -o ../${EXE} -nr ${FILES}
CXX=arm-linux-gnueabihf-g++
CC = arm-linux-gnueabihf-gcc

default: sketchy_dev

sketchy_fb: compile_x86

sketchy_dev: compile_dev

sketchy_arm: compile_arm

compile_x86: export CPP_FLAGS += -I/usr/include/freetype2 -lfreetype
compile_x86:
	cd okp/ && okp ${OKP_FLAGS} -- ${CPP_FLAGS}

compile_dev: export CPP_FLAGS += -I/usr/include/freetype2 -lfreetype
compile_dev:
	cd okp/ && okp ${OKP_FLAGS} -- -D"DEV=1" ${CPP_FLAGS}

compile_arm: export CPP_FLAGS += -I../vendor/freetype2/install/usr/local/include/freetype2 -L../vendor/freetype2/install/usr/local/lib/ -lfreetype

compile_arm:
	cd okp/ && CXX=arm-linux-gnueabihf-g++ okp ${OKP_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}

test_arm: compile_arm copy_arm
	HOST=${HOST} bash scripts/run_sketchy_arm.sh || true


copy_arm: compile_arm
	scp sketchy root@${HOST}:sketchy

view:
	python scripts/viewer.py

FREETYPE_PATH = ./vendor/freetype2
freetype_arm:
	cd vendor/freetype2 && bash autogen.sh
	cd vendor/freetype2 && CXX=${CXX} CC=${CC} ./configure --without-zlib --without-png --enable-static=yes --enable-shared=no  --without-bzip2 --host=arm-linux-gnueabihf

	cd vendor/freetype2 && CXX=${CXX} CC=${CC} make -j4
	cd vendor/freetype2 && DESTDIR=$(shell readlink -f vendor/freetype2/install) make install

freetype_x86:
	cd vendor/freetype2 && bash autogen.sh
	cd vendor/freetype2 && ./configure --without-zlib --without-png --enable-static=yes --enable-shared=no  --without-bzip2

	cd vendor/freetype2 && make -j4
	cd vendor/freetype2 && DESTDIR=$(shell readlink -f vendor/freetype2/install) make install
