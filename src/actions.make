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
	CXX=${CXX_BIN} okp ${OKP_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}

compile_arm_fast: export CPP_FLAGS += -O0 -g
compile_arm_fast:
	CXX=${CXX_BIN} okp ${OKP_FLAGS} -- -D"REMARKABLE=1" ${CPP_FLAGS}

compile_dev: export CPP_FLAGS += -O0 -g
compile_dev:
	okp ${OKP_FLAGS} -- -D"DEV=1" ${CPP_FLAGS} -D"DEV_KBD=\"${KBD}\""

compile_x86: export CPP_FLAGS += -O0 -g
compile_x86:
	okp ${OKP_FLAGS} -- ${CPP_FLAGS}

assets:
	# ${SRC_DIR} ${APP}
	bash ${ROOT_DIR}/scripts/build/build_assets.sh ${SRC_DIR}/${APP}/assets.h ${ASSET_DIR}

install-default:
	make copy

install_draft-default:
	ssh -C root@${HOST} mkdir -p /opt/etc/draft 2>/dev/null
	scp -C ${DRAFT} root@${HOST}:/opt/etc/draft/

resim:
	ARCH=dev make && cd ../../ && resim ./src/build/${EXE}

copy:
	ARCH=arm $(MAKE) compile
	if [ -n "${DRAFT}" ]; then make install_draft; fi

	ssh root@${HOST} killall -9 ${EXE} ${APP} || true
	ssh root@${HOST} mkdir -p ${DEST} 2>/dev/null
	scp -C ../build/${EXE} root@${HOST}:${DEST}/${APP}


stop:
	ssh root@${HOST} killall -9 ${EXE} || true

run: compile copy
	ssh root@${HOST} systemctl stop xochitl
	ssh root@${HOST} ${DEST}/${EXE}

test: export ARCH=arm
test: copy
	HOST=${HOST} bash scripts/run_app_arm.sh ${EXE} || true

lint:
	make compile OKP_FLAGS="--lint ${OKP_FLAGS}"

reboot:
	ssh root@10.11.99.1 systemctl start xochitl

%: %-default
	@ true

.PHONY: assets clean reboot
# vim: syntax=make
