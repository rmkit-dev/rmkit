OUTDIR=artifacts
mkdir ${OUTDIR}
docker run -i --rm -v "${PWD}/${OUTDIR}:/mnt/artifacts" rmkit /bin/bash << COMMANDS
mkdir -p src/build
ARCH=dev make
echo "FINISHED BUILDING"
./scripts/test/gen_app_screenshots.sh
echo "FINISHED TESTING"
mkdir -p /mnt/artifacts/test/
mkdir -p /mnt/artifacts/build/
mv src/build/*pnm /mnt/artifacts/test/
mv src/build/*out /mnt/artifacts/test/
mv src/build/* /mnt/artifacts/build/
chown -R $(id -u):$(id -u) /mnt/artifacts
COMMANDS

