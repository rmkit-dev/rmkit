OUTDIR=artifacts
PACKAGE="${1}"
ARCH=${ARCH:-rm}
mkdir ${OUTDIR}
docker run -i --rm -v "${PWD}/${OUTDIR}:/mnt/artifacts" rmkit /bin/bash << COMMANDS
mkdir -p src/build
ARCH=${ARCH} make ${PACKAGE}
mkdir -p /mnt/artifacts/${ARCH}/
cp -r src/build/* /mnt/artifacts/${ARCH}/
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS

