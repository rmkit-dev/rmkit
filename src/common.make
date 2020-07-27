HOST?=10.11.99.1
ARCH?=arm
CXX=arm-linux-gnueabihf-g++
CC = arm-linux-gnueabihf-gcc
CPP_FLAGS=-pthread -lpthread

VERSION=$(shell cat src/rmkit/version.cpy | sed 's/__version__=//;s/"//g')
KBD=`ls /dev/input/by-path/*kbd | head -n1`
# NOTE: $FILES and $EXE NEED TO BE DEFINED
OKP_FLAGS=-for -d ../cpp/ -o ../build/${EXE} -nr ${FILES}

default: compile

compile:
	# $$ARCH is ${ARCH}
ifeq ($(ARCH),x86)
	make compile_x86
else ifeq ($(ARCH),arm)
	make compile_arm
else ifeq ($(ARCH),dev)
	make compile_dev
else
	# Unsupported arch: ${ARCH}
	exit 1
endif

compile_arm: export CPP_FLAGS += -O3
compile_arm:
	CXX=arm-linux-gnueabihf-g++ okp ${OKP_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}

compile_dev: export CPP_FLAGS += -Og
compile_dev:
	okp ${OKP_FLAGS} -- -D"DEV=1" ${CPP_FLAGS} -D"DEV_KBD=\"${KBD}\""

compile_x86: export CPP_FLAGS += " -Og"
compile_x86:
	okp ${OKP_FLAGS} -- ${CPP_FLAGS}

copy:
	ARCH=arm $(MAKE) compile
	scp -C ../build/${EXE}.exe root@${HOST}:harmony/${EXE}
stop:
	ssh root@${HOST} killall ${EXE} || true
run: compile copy
	HOST=${HOST} bash build/${EXE}

test: export ARCH=arm
test: copy
	HOST=${HOST} bash scripts/run_app_arm.sh ${EXE} || true

# vim: syntax=make
