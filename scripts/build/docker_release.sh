OUTDIR=artifacts
TARGET=${TARGET:-rm}
FBINK=${FBINK}
CROSS_TC=${CROSS_TC:-arm-linux-gnueabihf}

mkdir ${OUTDIR}
docker run -i --rm -v "${PWD}/${OUTDIR}:/mnt/artifacts" rmkit:${TARGET} /bin/bash << COMMANDS
cd /rmkit/
mkdir -p src/build
echo "CURRENT DIR IS"
pwd
CROSS_TC=${CROSS_TC} FBINK=${FBINK} TARGET=${TARGET} make
CROSS_TC=${CROSS_TC} FBINK=${FBINK} TARGET=${TARGET} make strip
CROSS_TC=${CROSS_TC} FBINK=${FBINK} TARGET=${TARGET} make bundle
mkdir -p /mnt/artifacts/${TARGET}/
cp -r src/build/* /mnt/artifacts/${TARGET}/
rm /mnt/artifacts/${TARGET}/stb.*
rm /mnt/artifacts/${TARGET}/release.*
cp -r src/build/release.* /mnt/artifacts/${TARGET}/
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS
