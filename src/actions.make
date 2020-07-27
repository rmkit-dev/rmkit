include ../common.make

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

clean_exe:
	rm ../build/${EXE}

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
	scp -C ../build/${EXE} root@${HOST}:harmony/${EXE}
stop:
	ssh root@${HOST} killall ${EXE} || true
run: compile copy
	HOST=${HOST} bash build/${EXE}

test: export ARCH=arm
test: copy
	HOST=${HOST} bash scripts/run_app_arm.sh ${EXE} || true

# vim: syntax=make
