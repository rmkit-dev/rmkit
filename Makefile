BUILD_DIR=src/build

include src/common.make

default: harmony.exe remux.exe

dev: export ARCH=dev
dev: default

arm: export ARCH=arm
arm: default

x86: export ARCH=x86
x86: default

rmkit.h:
	mkdir src/build > /dev/null || true
	cd src/rmkit && make

harmony.exe:
	cd src/harmony && make

remux.exe:
	cd src/remux && make

demo.exe:
	cd src/demo && make

docker:
	docker build --tag rmharmony:latest .
	bash scripts/docker_release.sh

docker_install: docker
	echo "Not implemented yet"

bundle: harmony.exe remux.exe
	#BUILDING V: ${VERSION} ARCH: ${ARCH}
	mkdir -p ${BUILD_DIR}/harmony 2>/dev/null || true
	cp ${BUILD_DIR}/harmony.exe ${BUILD_DIR}/remux.exe ${BUILD_DIR}/harmony/
	cp contrib/remux.service ${BUILD_DIR}/harmony/
	cd ${BUILD_DIR}; zip release-${VERSION}.zip -r harmony/
	cat scripts/install_harmony.sh.template | sed 's/VERSION/${VERSION}/g' > scripts/install_harmony.sh
	cat scripts/try_harmony.sh.template | sed 's/VERSION/${VERSION}/g' > scripts/try_harmony.sh

view:
	python scripts/viewer.py
