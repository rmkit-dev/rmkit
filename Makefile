FILES=main.cpy ../vendor/lodepng/lodepng.cpp
HOST?=10.11.99.1
EXE="harmony"
CPP_FLAGS=-Og -pthread -lpthread
OKP_FLAGS=-for -d ../cpp/ -o ../build/bin/${EXE} -nr ${FILES}
LAUNCHER_FLAGS=-d ../cpp -o ../build/bin/launcher -for -nr launcher.cpy ../vendor/lodepng/lodepng.cpp
CXX=arm-linux-gnueabihf-g++
CC = arm-linux-gnueabihf-gcc
KBD=`ls /dev/input/by-path/*kbd | head -n1`
VERSION=$(shell cat okp/version.cpy | sed 's/__version__=//;s/"//g')

# {{{ SKETCHY MAIN CODE

default: harmony_dev

clean:
	rm cpp/ -fr
	mkdir build/bin -p

harmony_fb: compile_x86
harmony_dev: compile_dev
harmony_arm: compile_arm

compile_x86:
compile_x86:
	cd okp/ && okp ${OKP_FLAGS} -- ${CPP_FLAGS}

compile_dev:
compile_dev:
	cd okp/ && okp ${OKP_FLAGS} -- -D"DEV=1" ${CPP_FLAGS} -D"DEV_KBD=\"${KBD}\""

compile_arm:
compile_arm:
	cd okp/ && CXX=arm-linux-gnueabihf-g++ okp ${OKP_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}
copy_arm: compile_arm harmony_dir
	scp -C build/bin/harmony root@${HOST}:harmony/harmony
test_arm: compile_arm copy_arm
	HOST=${HOST} bash scripts/run_harmony_arm.sh || true

view:
	python scripts/viewer.py

bundle: compile_arm launcher_arm
	mkdir -p build/harmony 2>/dev/null || true
	cp build/bin/harmony build/bin/launcher build/harmony/
	cp contrib/harmony.service build/harmony/
	cd build; zip release-${VERSION}.zip -r harmony/
	cat scripts/install_harmony.sh.template | sed 's/VERSION/${VERSION}/g' > scripts/install_harmony.sh
	cat scripts/try_harmony.sh.template | sed 's/VERSION/${VERSION}/g' > scripts/try_harmony.sh

# }}}

# {{{ LAUNCHER COMPILATION
harmony_dir:
	ssh root@${HOST} mkdir harmony 2>/dev/null || true
launcher_dev:
	cd okp/ && okp ${LAUNCHER_FLAGS} -- -D"DEV=1" ${CPP_FLAGS} -g -lpthread -D"DEV_KBD=\"${KBD}\""

launcher_arm:
	cd okp/ && CXX=arm-linux-gnueabihf-g++ okp ${LAUNCHER_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS} -O3 -lpthread
stop_launcher:
	ssh root@${HOST} killall launcher || true
copy_launcher: launcher_arm stop_launcher harmony_dir
	scp -C build/bin/launcher root@${HOST}:harmony/launcher
test_launcher: launcher_arm copy_launcher
	HOST=${HOST} bash scripts/run_launcher_arm.sh || true
install_service:
	scp contrib/harmony.service root@${HOST}:/etc/systemd/system/
start_service:
	ssh root@{HOST} systemctl enable --now harmony
# }}}

# {{{ DOCKER BUILD
docker:
	docker build --tag rmharmony:latest .
	bash scripts/docker_release.sh

docker_install: docker
	echo "Not implemented yet"
# }}}
