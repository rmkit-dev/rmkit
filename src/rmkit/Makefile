include ../common.make

EXE=rmkit.h
FILES=rmkit.cpy ../vendor/lodepng/lodepng.cpp

# add single header (-sh) flag to OKP_FLAGS because we are compiling into rmkit.h
# requires okp >= 0.0.36
export OKP_FLAGS := -sh ${OKP_FLAGS}
export CPP_FLAGS := ${CPP_FLAGS} -DRMKIT_BUILD=1
