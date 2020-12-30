OUTDIR=artifacts
mkdir ${OUTDIR}
docker run -i --rm -v "${PWD}/${OUTDIR}:/mnt/artifacts" rmkit /bin/bash << COMMANDS
mkdir -p src/build
make
make bundle
mkdir -p /mnt/artifacts/files/
cp -r src/build/* /mnt/artifacts/files/
rm /mnt/artifacts/files/stb.o
rm /mnt/artifacts/files/release.*
cp -r src/build/release.* /mnt/artifacts
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS

