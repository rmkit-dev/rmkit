include ../actions.make

EXE=rmkit.h
FILES=rmkit.cpy

# add single header (-sh) flag to OKP_FLAGS because we are compiling into rmkit.h
# requires okp >= 0.0.36
export OKP_FLAGS := -sh ${OKP_FLAGS}
export CPP_FLAGS := ${CPP_FLAGS}

APP=rmkit
ASSET_DIR=assets/

clean:
	rm -f ${SRC_DIR}/build/${EXE}
