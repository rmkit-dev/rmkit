OUTDIR=artifacts
PACKAGE="${1}"
mkdir ${OUTDIR}
docker run -i --rm -v "${PWD}/${OUTDIR}:/mnt/artifacts" rmkit /bin/bash << COMMANDS
mkdir -p src/build
make ${PACKAGE}
mkdir -p /mnt/artifacts/files/
cp -r src/build/* /mnt/artifacts/files/
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS

