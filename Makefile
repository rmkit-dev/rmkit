#!/usr/bin/env bash
default: build
include src/common.make

# Use `make <app>` to build any app individually
APPS=harmony remux demo minesweeper
LINT_APPS=$(foreach app, $(APPS), lint_$(app))
CLEAN_APPS=$(foreach app, $(APPS), clean_$(app))
INSTALL_APPS=$(foreach app, $(APPS), install_$(app))

$(APPS): %: rmkit.h
	cd src/${@} && make

$(INSTALL_APPS): %: rmkit.h
	cd src/$(@:install_%=%) && make copy

$(CLEAN_APPS): %:
	cd src/$(@:clean_%=%) && make clean

$(LINT_APPS): %:
	cd src/$(@:lint_%=%) && make lint

build: $(APPS)
	echo "BUILT ALL APPS"

install: rmkit.h
	$(foreach app, $(APPS), cd src/${app} && make copy; cd ${ROOT}; )

clean:
	$(foreach app, $(APPS), cd src/${app} && make clean; cd ${ROOT}; )

default: build

lint: $(LINT_APPS)

dev: export ARCH=dev
dev: default

arm: export ARCH=arm
arm: default

x86: export ARCH=x86
x86: default

rmkit.h:
	mkdir src/build > /dev/null || true
	cd src/rmkit && make

docker:
	docker build --tag rmharmony:latest .
	bash scripts/build/docker_release.sh

docker_install: docker
	echo "Not implemented yet"

bundle: harmony remux
	#BUILDING V: ${VERSION} ARCH: ${ARCH}
	mkdir -p ${BUILD_DIR}/harmony 2>/dev/null || true
	# TODO: use ${APPS} here
	cp ${BUILD_DIR}/harmony.exe ${BUILD_DIR}/remux.exe ${BUILD_DIR}/harmony/
	cp contrib/remux.service ${BUILD_DIR}/harmony/

	cd ${BUILD_DIR}; zip release-${VERSION}.zip -r harmony/
	cat scripts/run/install_harmony.sh.template | sed 's/VERSION/${VERSION}/g' > scripts/run/install_harmony.sh
	cat scripts/run/try_harmony.sh.template | sed 's/VERSION/${VERSION}/g' > scripts/run/try_harmony.sh

view:
	python scripts/dev/viewer.py

NATURAL_DOCS?=mono ~/tonka/apps/Natural\ Docs/NaturalDocs.exe
natural_docs:
	bash scripts/docs/augment_docs.sh
	${NATURAL_DOCS} -p config/ -i src/ -o html docs/html/ -xi src/cpp/ -xi src/build
watch_docs:
	find ./src/ ./config/ | while true; do entr -d make natural_docs; sleep 0.5; done


.PHONY:build view install
