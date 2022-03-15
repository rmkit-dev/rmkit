OUTDIR=artifacts
TARGET=${TARGET:-rm}
mkdir ${OUTDIR}
docker run -i --rm -v "${PWD}/${OUTDIR}:/mnt/artifacts" rmkit /bin/bash << COMMANDS
mkdir -p src/build
TARGET=${TARGET} make
TARGET=${TARGET} make strip
TARGET=${TARGET} make bundle
mkdir -p /mnt/artifacts/${TARGET}/
cp -r src/build/* /mnt/artifacts/${TARGET}/
rm /mnt/artifacts/${TARGET}/stb.*
rm /mnt/artifacts/${TARGET}/release.*
cp -r src/build/release.* /mnt/artifacts/${TARGET}/
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS
