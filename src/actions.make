include ../common.make
SRC_DIR=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
ROOT_DIR=$(shell realpath -s ${SRC_DIR}/../)
APP?=$(EXE:.exe=)

compile:
	# $$ARCH is ${ARCH}
ifeq ($(ARCH),x86)
	make compile_x86
else ifeq ($(ARCH),arm)
	make compile_arm
else ifeq ($(ARCH),arm-dev)
	make compile_arm_fast
else ifeq ($(ARCH),dev)
	make compile_dev
else
	# Unsupported arch: ${ARCH}
	exit 1
endif


clean:
	rm ${SRC_DIR}/build/${EXE}

compile_arm: export CPP_FLAGS += -O2
compile_arm:
	CXX=arm-linux-gnueabihf-g++ okp ${OKP_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}

compile_arm_fast: export CPP_FLAGS += -O0 -g
compile_arm_fast:
	CXX=arm-linux-gnueabihf-g++ okp ${OKP_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}

compile_dev: export CPP_FLAGS += -O0 -g
compile_dev:
	okp ${OKP_FLAGS} -- -D"DEV=1" ${CPP_FLAGS} -D"DEV_KBD=\"${KBD}\""

compile_x86: export CPP_FLAGS += -O0 -g
compile_x86:
	okp ${OKP_FLAGS} -- ${CPP_FLAGS}

assets:
	# ${SRC_DIR} ${APP}
	bash ${ROOT_DIR}/scripts/build/build_assets.sh ${SRC_DIR}/${APP}/assets.h ${ASSET_DIR}

_install:
	make copy

copy:
	ARCH=arm $(MAKE) compile
	ssh root@${HOST} killall ${EXE} || true # finally
	scp -C ../build/${EXE} root@${HOST}:${DEST}/${EXE}

stop:
	ssh root@${HOST} killall ${EXE} || true

run: compile copy
	ssh root@${HOST} systemctl stop xochitl
	ssh root@${HOST} ${DEST}/${EXE}

test: export ARCH=arm
test: copy
	HOST=${HOST} bash scripts/run_app_arm.sh ${EXE} || true

lint:
	make compile OKP_FLAGS="--lint ${OKP_FLAGS}"

.PHONY: assets clean
# vim: syntax=make
