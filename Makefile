FILES=main.cpy ../vendor/lodepng/lodepng.cpp
HOST?=10.11.99.1
EXE="harmony"
CPP_FLAGS=-O3 -g
OKP_FLAGS=-for -d ../cpp/ -o ../build/bin/${EXE} -nr ${FILES}
LAUNCHER_FLAGS=-d ../cpp -o ../build/bin/launcher -for -nr launcher.cpy
CXX=arm-linux-gnueabihf-g++
CC = arm-linux-gnueabihf-gcc

# {{{ SKETCHY MAIN CODE
default: harmony_dev

harmony_fb: compile_x86
harmony_dev: compile_dev
harmony_arm: compile_arm

compile_x86: export CPP_FLAGS += -I/usr/include/freetype2 -lfreetype -I../vendor/lodepng
compile_x86:
	cd okp/ && okp ${OKP_FLAGS} -- ${CPP_FLAGS}

compile_dev: export CPP_FLAGS += -I/usr/include/freetype2 -lfreetype -I../vendor/lodepng
compile_dev:
	cd okp/ && okp ${OKP_FLAGS} -- -D"DEV=1" ${CPP_FLAGS}

compile_arm: export CPP_FLAGS += -I../vendor/freetype2/install/usr/local/include/freetype2 -L../vendor/freetype2/install/usr/local/lib/ -lfreetype -I../vendor/lodepng
compile_arm:
	cd okp/ && CXX=arm-linux-gnueabihf-g++ okp ${OKP_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}
copy_arm: compile_arm harmony_dir
	scp -C harmony root@${HOST}:harmony/harmony
test_arm: compile_arm copy_arm
	HOST=${HOST} bash scripts/run_harmony_arm.sh || true

view:
	python scripts/viewer.py

bundle: compile_arm launcher_arm
	mkdir -p build/harmony 2>/dev/null || true
	cp build/bin/harmony build/bin/launcher build/harmony/
	cp contrib/harmony.service build/harmony/
	cd build; zip release.zip -r harmony/

# }}}

# {{{ LAUNCHER COMPILATION
harmony_dir:
	ssh root@${HOST} mkdir harmony 2>/dev/null || true
launcher_arm:
	cd okp/ && CXX=arm-linux-gnueabihf-g++ okp ${LAUNCHER_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}
stop_launcher:
	ssh root@${HOST} killall launcher || true
copy_launcher: launcher_arm stop_launcher harmony_dir
	scp -C launcher root@${HOST}:harmony/launcher
test_launcher: launcher_arm copy_launcher
	HOST=${HOST} bash scripts/run_launcher_arm.sh || true
install_service:
	scp contrib/harmony.service root@${HOST}:/etc/systemd/system/
start_service:
	ssh root@{HOST} systemctl enable --now harmony
# }}}

# {{{ VENDOR BUILDS
FREETYPE_PATH = ./vendor/freetype2
freetype_arm:
	cd vendor/freetype2 && bash autogen.sh
	cd vendor/freetype2 && CXX=${CXX} CC=${CC} ./configure --without-zlib --without-png --without-bzip2 --without-brotli --without-harfbuzz --host=arm-linux-gnueabihf --enable-static=yes --enable-shared=no

	cd vendor/freetype2 && CXX=${CXX} CC=${CC} make -j4
	cd vendor/freetype2 && DESTDIR=$(shell readlink -f vendor/freetype2/install) make install

freetype_x86:
	cd vendor/freetype2 && bash autogen.sh
	cd vendor/freetype2 && ./configure --without-zlib --without-png --enable-static=yes --enable-shared=no  --without-bzip2

	cd vendor/freetype2 && make -j4
	cd vendor/freetype2 && DESTDIR=$(shell readlink -f vendor/freetype2/install) make install
# }}}
