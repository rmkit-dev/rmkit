OUTDIR=artifacts
ARCH=${ARCH:-rm}
mkdir ${OUTDIR}
docker run -i --rm -v "${PWD}/${OUTDIR}:/mnt/artifacts" rmkit /bin/bash << COMMANDS
mkdir -p src/build
ARCH=${ARCH} make
ARCH=${ARCH} make strip
ARCH=${ARCH} make bundle
mkdir -p /mnt/artifacts/${ARCH}/
cp -r src/build/* /mnt/artifacts/${ARCH}/
rm /mnt/artifacts/${ARCH}/stb.*
rm /mnt/artifacts/${ARCH}/release.*
cp -r src/build/release.* /mnt/artifacts/${ARCH}/
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS

